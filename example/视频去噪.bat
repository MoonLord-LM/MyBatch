ffmpeg -i "output.mp4" -vf "hqdn3d" -c:v libx264 -crf 18 -preset fast -c:a aac output1.mp4
ffmpeg -i "output.mp4" -vf "smartblur=5:0.8:0" -c:v libx264 -crf 18 -preset fast -c:a aac output2.mp4
ffmpeg -i "output.mp4" -vf "nlmeans=7:5:10" -c:v libx264 -crf 18 -preset fast -c:a aac output3.mp4
ffmpeg -i "output.mp4" -vf "hqdn3d=5:4:8:8" -c:v libx264 -crf 18 -preset fast -c:a aac output4.mp4

pause
exit
