Antialiasing an image:
----------------------

This example makes use of a simple technique called SUPERSAMPLING. It can 
be easily used with images created in real time, using the TCanvas 
drawing different methods (Line, Rectangle, Ellipse, etc.).

In brief: to achieve an accurate, antialiased rendering of an image:

1) Draw it scaled at an enlarged size (in this example, we make the image 
three times larger)..

2) Reduce it to the desired output size, recalculating the ouput pixel 
color.

3) The output color is obtained as an average of the red, green and blue 
values of each of the 9 pixels in the enlarged image that correspond to a 
single pixel in the output image.


Getting/Setting a bitmap's individual pixels:
---------------------------------------------

The easiest way to do this is, of course, to use TCanvas.Pixels property. 
This method, however, is rather slow... If you need really fast access to 
a bitmap pixels, you might use the TBitmap.Scanline property, that returns 
a pointer to the first pixel in a given bitmap row. This could be about 
50 times faster!

To do this, you must include 'graphics' in the 'uses' clause of your code 
and declare the following constants and types before the implementation 
section of your code:

  const
      MaxPixelCount   =  32768;

  type
      pRGBArray  =  ^TRGBArray;
      TRGBArray  =  ARRAY[0..MaxPixelCount-1] OF TRGBTriple;


and, to access a given line:

1) declare a variable of type pRGBArray, and a variable of tipe 
TRGBTriple:

  var BmpLine: pRGBArray:
      Pixel: TRGBTriple;

2) assign it to a bitmap scan line:

  BmpLine := Bitmap.ScanLine[0];


Then you can acces each individual pixel in that line like that:

  Pixel := BmpLine[0];

NOTE: The ScanLine property only works properly with 24 bits-per-pixel 
bitmaps; if you try to use it on other kind of bitmaps, the results may 
be unpredictable (and really, really sloooooow)...


Hope this sample may be useful to you. Good luck!   :)



Files included:
---------------

FastAntiAlias.dpr	(Delphi project: for Delphi 3 and upper)
FAAlias.pas.		(Main form code)
FAAlias.dfm.		(Main form)
FastAntiAlias.exe	(Compiled example)
ReadMe.txt		(This file)

You may freely distribute this sample code, providing you include all of
the above files unchanged.



LEGAL DISCLAIMER:
-----------------

The author cannot give any guarantees, explicit or implicit, that this code 
will work properly under every possible circumstance. Use it at your own 
risk... Sorry. After all, it is free!



Nacho Urenda (nurenda@wanadoo.es)