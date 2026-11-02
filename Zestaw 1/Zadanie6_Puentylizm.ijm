// Zadanie 6: puentylizm w ImageJ.
// Metoda: losowanie pikseli i rysowanie kolek w ich kolorach.

if (nImages == 0)
    exit("Najpierw otworz kolorowy obraz.");

if (bitDepth != 24)
    exit("Wybierz kolorowy obraz i uzyj Image > Type > RGB Color.");

sourceID = getImageID();
w = getWidth();
h = getHeight();

// Parametry efektu.
diameter = 9;
density = 3;
numberOfDots = maxOf(1, round(density * w * h / (diameter * diameter)));
offset = floor(diameter / 2);

setBatchMode(true);
newImage("Zadanie6_Puentylizm", "RGB white", w, h, 1);
resultID = getImageID();

for (i = 0; i < numberOfDots; i++) {
    x = floor(random() * w);
    y = floor(random() * h);

    // Kolor zawsze pobieramy z oryginalnego obrazu.
    selectImage(sourceID);
    pixelColor = getPixel(x, y);

    // Rysujemy wypelnione kolko na osobnym obrazie.
    selectImage(resultID);
    setColor(pixelColor);
    fillOval(x - offset, y - offset, diameter, diameter);
}

setBatchMode(false);

