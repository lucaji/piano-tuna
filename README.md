# piano-tuna
An iOS app for helping tuning pianos without the laborous usage of mutes. It employs inharmonicity analysis for best tune perception too.


## References and Documentation

A recollection of the links found in the source code pointing to reference material, docs, papers and articles:

- [audio manipulation using AVEngine](https://blog.metova.com/audio-manipulation-using-avaudioengine)

- [Wavelets](https://archive.org/details/cnx-org-col11454/mode/2up)

- [linear interpolation](https://stackoverflow.com/questions/1125666/how-do-you-do-bicubic-or-other-non-linear-interpolation-of-re-sampled-audio-da) see below.

### Polynomial Interpolators for High-Quality Resampling of Oversampled Audio

Revised version (October 2001): deip.pdf (501 KiB)

Abstract:

"This paper discusses piece-wise polynomial interpolators used in audio resampling and presents new low-order designs that are optimized for high-quality resampling of oversampled audio. Source code and useful tables for using the interpolators are included."

Scarcely documented C++ source code is included in depoly folder.

Old version (August 2001): deip-original.pdf (491 KiB)
