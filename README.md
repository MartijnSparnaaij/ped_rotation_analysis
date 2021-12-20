# Pedestrian Rotation Analysis Tool

The Pedestrian Rotation Analysis Tool is a small Matlab based tool that enables a user to obtain the upper body rotation of pedestrians.

## How to use

Start Matlab and set the current directory to directory containing the m-files (i.e. shoulderGui.m etc.). Next run shoulderGui.m. The following window should open:

![Start screen](images/001_start_screen.jpg)

The start screen shows two options:
1. Start a new analysis
2. Continue an analysis

Both options are explained in more detail below.

### Start new analysis

#### Load video

Click the load video button to open a file open dialog and select the video file.

![Load video](images/002_load_video.jpg)

After succesfully loading the file, the first frame of the video will be shown. The load another video click the load button again. 

![Video loaded](images/003_video_loaded.jpg)

After you have loaded the video, click next and a file dialog will open and ask you to select a file to which you want to save the analysis data. The structure of this output file and which data is saved in it is explained in more detail in the last part of this readme.

#### Set measurement rectangle

The analyses of shoulder rotations are based on a measurement area whereby the measurement area encloses the space where the shoulder rotations of the pedestrians are of interest for the analysis. The measurment rectangle that you have to draw in this step serves as a visual aid. The advice is to draw it at approximately the avarage head height of the participants. By doing this you can easily see if a pedestrian is within the measurement area by looking at the white dot on the cap they are wearing. If the dot within the marked area or on the line the participant is within the measurement area and the location of the shoulder points should be marked. If the dot is outside of the area the shoulders should not be marked.

![Set measurement rectangle](images/004_set_meas_rectangle.jpg)

To draw the measurement rectangle, click on the picture using the left mouse button and keep the mouse button pressed. By clicking on the picture the two corner points of a rectangle will appear and by keeping the mouse button pressed you can drag one of the corner points to create a rectangle. If you want to change the location of either of the corner points you can click and drag. If you want to change the rotation of the rectangle, click on either of the corner points using the right mouse button. A dialog will appear and within this dialog you can change the angle (in degrees) of the rectangle.

![Measurement rectangle set](images/005_meas_rectangle_set.jpg)

To place the corner points of the rectangle more precisely you can use the zoom buttom to zoom in (and zoom out again if you want to).

![Measurement rectangle zoom](images/006_meas_rectangle_set_zoom.jpg)

If you are satisfied with the measurement rectangle click next to continue.

#### Set interval

The next step enables you to set the interval for the analysis. This interval determines which frames are part of the analysis. If this number is 1, every frame is used in the analysis. If this number is, for example, 50 only 1 in 5 frames is used in the analysis.

![Set interval](images/007_set_interval.jpg)

Once you set the interval click next to continue.

#### Set group names

The last step before you can start the anlaysis is to set the names of the groups. A group is the collection fo pedestrian which have the same direction of travel. For example, in a bidirectional flow you have two groups. One walking from right to left and one walking from left to right. By selecting logical names for each group it is easier during the analysis to see for which group you need to mark the shoulder points. The second picture provides an example for a bidirectional case.

![Set group names](images/008_group_names_set.jpg)
![Group names set](images/009_set_group_names.jpg)

#### Perform analysis


![shoulder marking step 1](images/012_shoulder_marking_step_1.jpg)
![shoulder marking step 2](images/013_shoulder_marking_step_2.jpg)
![shoulder marking step 3](images/014_shoulder_marking_step_3.jpg)
![shoulder marking step 4](images/015_shoulder_marking_step_4.jpg)
![shoulder marking step 5](images/016_shoulder_marking_step_5.jpg)
![shoulder marking step 6](images/017_shoulder_marking_step_6.jpg)

### Continue from existing analysis


## Output file format

The analysis data is saved to a mat-file whereby the data is a structure with the following fields:
1. video: A structure contaning information about the video data used for the analysis.
2. analysisStepCount: The number of frames that are part of the analysis provided the given interval and number of frames in the video.
3. interval: The analysis frame interval
4. lastStepWithProcessedData: The last analysis step that contains shoulder rotation data
5. rectangle: A structure contaning information about the desnity rectangle used for the analysis.
6. groups: An array with 2 stuctures (1 per group) containing the rotation data

The video, rectangle and group structures are explained in more detail below.

### Video data structure

### Rectangle data structure

### Groups data structure




