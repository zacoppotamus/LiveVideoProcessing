# Run from sketch folder
# ffmpeg -ss 00:00:00 -i data/footage.mp4 -to 00:00:10 -c copy data/cut.mp4
# ffmpeg -i data/cut.mp4  data/frames/img%03d.png
processing-java --sketch=`pwd` --run
ffmpeg -f image2 -r 24  -i editedFrames/img%03d.png videos/output_%03d.mp4
