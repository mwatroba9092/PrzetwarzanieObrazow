// Zadanie 9: jeden kanal 8-bit 50x65 -> 500x650.
// Uruchamiaj osobno na oryginalnych kanalach R, G i B.
// Konwencja: Edge-aligned / Corner-aligned.
// u = m*49/499, v = n*64/649.
// b, d: najblizsze rozne piksele wedlug odleglosci euklidesowej.
// Przy remisie wybierany jest najpierw mniejszy y, potem mniejszy x.
// Wynik 8-bit: pojedyncze zaokraglenie do najblizszej liczby calkowitej.

if (nImages == 0)
    exit("Wybierz najpierw oryginalny kanal R, G lub B.");
if (getWidth() != 50 || getHeight() != 65)
    exit("Wybierz oryginalny kanal 50x65, nie powiekszony wynik.");
if (bitDepth != 8)
    exit("Wybierz pojedynczy kanal 8-bit. RGB rozdziel przez Image > Color > Split Channels.");

methods = newArray("a - Nearest neighbor", "b - Srednia 2 najblizszych",
    "c - Interpolacja dwuliniowa", "d - Srednia min i max z 4 najblizszych");
Dialog.create("Zadanie 9 - skalowanie jednego kanalu");
Dialog.addChoice("Metoda:", methods, methods[1]);
Dialog.show();
choice = Dialog.getChoice();
method = 0;
for (i = 0; i < methods.length; i++)
    if (choice == methods[i]) method = i;

suffixes = newArray("_a", "_b", "_c", "_d");
channelTitle = getTitle();
w = getWidth();
h = getHeight();
outW = 500;
outH = 650;
data = readChannel(channelTitle, w, h);
setBatchMode(true);

// Dla c sasiedztwo wynika bezposrednio z komorki interpolacji.
count = 1;
if (method != 2) count = outW * outH;
nearest = newArray(count);
near0 = newArray(count);
near1 = newArray(count);
near2 = newArray(count);
near3 = newArray(count);
if (method != 2)
    prepareMaps(w, h, outW, outH, nearest, near0, near1, near2, near3);

scaleChannel(channelTitle + suffixes[method], data, method, w, h, outW, outH,
    nearest, near0, near1, near2, near3);
setBatchMode("exit and display");
showProgress(1);

function readChannel(title, w, h) {
    selectImage(title);
    data = newArray(w * h);
    for (yy = 0; yy < h; yy++)
        for (xx = 0; xx < w; xx++)
            data[yy * w + xx] = getPixel(xx, yy);
    return data;
}

function prepareMaps(w, h, outW, outH, nearest, near0, near1, near2, near3) {
    distances = newArray(4);
    indices = newArray(4);
    for (oy = 0; oy < outH; oy++) {
        v = oy * (h - 1) / (outH - 1);
        cy = round(v);
        for (ox = 0; ox < outW; ox++) {
            u = ox * (w - 1) / (outW - 1);
            cx = round(u);
            p = oy * outW + ox;
            nearest[p] = cy * w + cx;
            for (k = 0; k < 4; k++) {
                distances[k] = 1e30;
                indices[k] = -1;
            }

            // Otoczenie 3x3 zawiera cztery najblizsze punkty siatki.
            for (sy = maxOf(0, cy - 1); sy <= minOf(h - 1, cy + 1); sy++) {
                for (sx = maxOf(0, cx - 1); sx <= minOf(w - 1, cx + 1); sx++) {
                    distance = (u - sx) * (u - sx) + (v - sy) * (v - sy);
                    for (k = 0; k < 4; k++) {
                        if (distance < distances[k]) {
                            for (j = 3; j > k; j--) {
                                distances[j] = distances[j - 1];
                                indices[j] = indices[j - 1];
                            }
                            distances[k] = distance;
                            indices[k] = sy * w + sx;
                            k = 4;
                        }
                    }
                }
            }
            near0[p] = indices[0];
            near1[p] = indices[1];
            near2[p] = indices[2];
            near3[p] = indices[3];
        }
        showProgress(oy + 1, outH);
    }
}

function scaleChannel(title, data, method, w, h, outW, outH,
    nearest, near0, near1, near2, near3) {
    newImage(title, "8-bit black", outW, outH, 1);
    for (oy = 0; oy < outH; oy++) {
        v = oy * (h - 1) / (outH - 1);
        y0 = floor(v);
        y1 = minOf(y0 + 1, h - 1);
        topWeight = 1 - (v - y0);
        for (ox = 0; ox < outW; ox++) {
            p = oy * outW + ox;

            if (method == 0) {
                // a: wartosc jednego najblizszego piksela.
                value = data[nearest[p]];
            } else if (method == 1) {
                // b: srednia dwoch roznych najblizszych pikseli.
                value = (data[near0[p]] + data[near1[p]]) / 2;
            } else if (method == 2) {
                // c: cztery narozniki komorki i wzor z wykladu.
                u = ox * (w - 1) / (outW - 1);
                x0 = floor(u);
                x1 = minOf(x0 + 1, w - 1);
                leftWeight = 1 - (u - x0);
                q0 = leftWeight * data[y0 * w + x0] +
                    (1 - leftWeight) * data[y0 * w + x1];
                q1 = leftWeight * data[y1 * w + x0] +
                    (1 - leftWeight) * data[y1 * w + x1];
                value = topWeight * q0 + (1 - topWeight) * q1;
            } else {
                // d: polowa sumy minimum i maksimum, bez sredniej z czterech.
                a = data[near0[p]];
                b = data[near1[p]];
                c = data[near2[p]];
                d = data[near3[p]];
                lowest = minOf(minOf(a, b), minOf(c, d));
                highest = maxOf(maxOf(a, b), maxOf(c, d));
                value = (lowest + highest) / 2;
            }
            setPixel(ox, oy, round(value));
        }
        showProgress(oy + 1, outH);
    }
}

