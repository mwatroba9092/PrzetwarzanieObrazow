// Zadanie 11 - dyfuzja bledow na lwy.png.
// Skanowanie: od lewej do prawej, od gory do dolu, bez serpentyny.
// Sasiadow poza obrazem pomijamy, bez zmiany pozostalych wag.
// Paleta 5 odcieni: progi 20, 40, 60, 120 z diagramu w zadaniu.
// Oryginal pozostaje bez zmian, kazde uruchomienie tworzy nowy obraz.

if (nImages == 0)
    exit("Otworz najpierw oryginalny obraz lwy.png.");
if (bitDepth() != 8)
    exit("Wybierz obraz lwy w skali szarosci 8-bit: Image > Type > 8-bit.");
getDimensions(w, h, channels, slices, frames);
if (channels * slices * frames != 1)
    exit("Wybierz pojedynczy obraz, nie stos ani obraz wielokanalowy.");
sourceTitle = getTitle();

methods = newArray("11a - Floyd-Steinberg, T=91",
    "Porownanie - Floyd-Steinberg, T=128",
    "11b - Jarvis-Judice-Ninke, T=91",
    "11b - Jarvis-Judice-Ninke, 5 odcieni (diagram)");
titles = newArray("11a_FS_T91", "Porownanie_FS_T128", "11b_JJN_T91", "11b_JJN_5_odcieni");
Dialog.create("Zadanie 11 - dyfuzja bledow");
Dialog.addChoice("Wariant:", methods, methods[0]);
Dialog.show();
choice = Dialog.getChoice();
method = 0;
for (i = 0; i < methods.length; i++)
    if (choice == methods[i]) method = i;

threshold = 91;
if (method == 1) threshold = 128;
paletteMode = 0;
if (method == 3) paletteMode = 1;

if (method < 2) {
    dx = newArray(1, -1, 0, 1);
    dy = newArray(0, 1, 1, 1);
    weights = newArray(7, 3, 5, 1);
    denominator = 16;
} else {
    dx = newArray(1, 2, -2, -1, 0, 1, 2, -2, -1, 0, 1, 2);
    dy = newArray(0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2);
    weights = newArray(7, 5, 3, 5, 7, 5, 3, 1, 3, 5, 3, 1);
    denominator = 48;
}

data = newArray(w * h);
sourceSum = 0;
for (y = 0; y < h; y++) {
    for (x = 0; x < w; x++) {
        data[y * w + x] = getPixel(x, y);
        sourceSum += data[y * w + x];
    }
}

setBatchMode(true);
newImage(titles[method], "8-bit black", w, h, 1);
outputSum = dither(data, w, h, threshold, paletteMode, dx, dy, weights, denominator);
run("Grays");
setMinAndMax(0, 255);
setBatchMode("exit and display");
showProgress(1);
print("Zadanie 11: " + methods[method]);
print("Oryginal: " + sourceTitle);
print("Srednia jasnosc oryginalu: " + d2s(sourceSum / (w * h), 3));
print("Srednia jasnosc wyniku: " + d2s(outputSum / (w * h), 3));

function quantize(value, threshold, paletteMode) {
    if (paletteMode == 0) {
        if (value < threshold) return 0;
        return 255;
    }
    if (value < 20) return 0;
    if (value < 40) return 64;
    if (value < 60) return 128;
    if (value < 120) return 192;
    return 255;
}

function spreadError(data, w, h, x, y, error, dx, dy, weights, denominator) {
    for (k = 0; k < weights.length; k++) {
        nx = x + dx[k];
        ny = y + dy[k];
        if (nx >= 0 && nx < w && ny >= 0 && ny < h)
            data[ny * w + nx] += error * weights[k] / denominator;
    }
}

function dither(data, w, h, threshold, paletteMode, dx, dy, weights, denominator) {
    total = 0;
    for (yy = 0; yy < h; yy++) {
        for (xx = 0; xx < w; xx++) {
            pos = yy * w + xx;
            oldpixel = data[pos];
            newpixel = quantize(oldpixel, threshold, paletteMode);
            data[pos] = newpixel;
            setPixel(xx, yy, newpixel);
            total += newpixel;
            error = oldpixel - newpixel;
            spreadError(data, w, h, xx, yy, error, dx, dy, weights, denominator);
        }
        showProgress(yy + 1, h);
    }
    return total;
}
