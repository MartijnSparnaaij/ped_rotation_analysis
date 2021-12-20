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

After successfully loading the file, the first frame of the video will be shown. The load another video click the load button again. 

![Video loaded](images/003_video_loaded.jpg)

After you have loaded the video, click next and a file dialog will open and ask you to select a file to which you want to save the analysis data. The structure of this output file and which data is saved in it is explained in more detail in the last part of this readme.

#### Set measurement rectangle

The analyses of shoulder rotations are based on a measurement area whereby the measurement area encloses the space where the shoulder rotations of the pedestrians are of interest for the analysis. The measurement rectangle that you have to draw in this step serves as a visual aid. The advice is to draw it at approximately the average head height of the participants. By doing this you can easily see if a pedestrian is within the measurement area by looking at the white dot on the cap they are wearing. If the dot is within the marked area or on the line the participant is within the measurement area and the location of the shoulder points should be marked. If the dot is outside of the area the shoulders should not be marked.

![Set measurement rectangle](images/004_set_meas_rectangle.jpg)

To draw the measurement rectangle, click on the picture using the left mouse button and keep the mouse button pressed. By clicking on the picture the two corner points of a rectangle will appear and by keeping the mouse button pressed you can drag one of the corner points to create a rectangle. If you want to change the location of either of the corner points you can click and drag. If you want to change the rotation of the rectangle, click on either of the corner points using the right mouse button. A dialog will appear and within this dialog you can change the angle (in degrees) of the rectangle.

![Measurement rectangle set](images/005_meas_rectangle_set.jpg)

To place the corner points of the rectangle more precisely you can use the zoom button to zoom in (and zoom out again if you want to).

![Measurement rectangle zoom](images/006_meas_rectangle_set_zoom.jpg)

If you are satisfied with the measurement rectangle click next to continue.

#### Set interval

The next step enables you to set the interval for the analysis. This interval determines which frames are part of the analysis. If this number is 1, every frame is used in the analysis. If this number is, for example, 50 only 1 in 50 frames is used in the analysis.

![Set interval](images/007_set_interval.jpg)

Once you set the interval click next to continue.

#### Set group names

The last step before you can start the analysis is to set the names of the groups. A group is the collection fo pedestrian which have the same direction of travel. For example, in a bidirectional flow you have two groups. One walking from right to left and one walking from left to right. By selecting logical names for each group it is easier during the analysis to see for which group you need to mark the shoulder points. The figure provides an example for a bidirectional case.

![Set group names](images/008_group_names_set.jpg)

After you have provided the group names you can click next to begin the analysis.

#### Perform analysis

The core of the analysis is that, per frame and per group, you mark the shoulder points of all pedestrians who are within the measurement area. The analysis of each frame is subdivided into two steps. One for each of the two groups. 

The figure below shows the staring point for the analysis of a frame. Above the picture of the frame you can see which step out of the total amount of steps this is. So in this example it is the 35th frame out of the 123 frames that need to be analysed. The total number of frames that need to be analysed depends on the total number of frames in the video and the interval you set. On the left of the picture you see that you are currently in the process of performing the analysis for the group that walks from left to right by the fact that this text is displayed in bold.

![shoulder marking step 1](images/012_shoulder_marking_step_1.jpg)

The task now is to mark the shoulders of all pedestrian who are within the measurement area and who are walking from left to right. For every pedestrians you have to mark the shoulders in the following manner. First click on the center of the blue dot on the left shoulder of the pedestrian. A red dot will appear.

![shoulder marking step 2](images/013_shoulder_marking_step_2.jpg)

Now click on the center of the blue dot on the right shoulder. A green dot appears as well as a line connecting the two dots. To can drag both of the dots to change their position. If you want to remove the dot, click on it using your right mouse button.

![shoulder marking step 3](images/014_shoulder_marking_step_3.jpg)

Now repeat this step for all other pedestrians of the same group that are within the measurement area. And if all shoulders are marked click next.

![shoulder marking step 4](images/015_shoulder_marking_step_4.jpg)

By clicking next you can see that:
1) The text of the left that is bold has changed from the first group to the next one
2) The shoulder point of the other group that you have already marked have turned blue and you can no longer move them or remove them. If you still want to move them or remove them you can click previous. 

![shoulder marking step 5](images/016_shoulder_marking_step_5.jpg)

Now you have to mark all the shoulders of the second group using the same method and once you finished this click next to continue to the next frame until you reach the end of the analysis.

![shoulder marking step 6](images/017_shoulder_marking_step_6.jpg)

Every time you click next or previous the program will save all data so you can stop at any time during the analysis and close the window without losing data.

### Continue from existing analysis

If you choose the option "Continue analysis" in the start screen, a file dialog will appear where you can select the mat-file that contains the data of an analysis you performed previously. The program will now load the data and you can continue the analysis where you left of last time. To quickly go to any step use the "Go to step" button. If you click this button a dialog will open and you can set the step number you want to go to directly. The number in brackets you see in the dialog (after the text "Go to step") indicates the last step which contains any marked shoulder which gives you an indication of where you left of last time.

You can also change some of the settings by clicking previous. For example, you can change the interval to include more frames in the analysis. You can do this without losing data.

## Output file format

The analysis data is saved to a mat-file whereby the data is a structure with the following fields:
1. video: A structure containing information about the video data used for the analysis.
2. analysisStepCount: The number of frames that are part of the analysis provided the given interval and number of frames in the video.
3. interval: The analysis frame interval
4. lastStepWithProcessedData: The last analysis step that contains shoulder rotation data
5. rectangle: A structure containing information about the density rectangle used for the analysis.
6. groups: An array with 2 structures (1 per group) containing the rotation data

The video, rectangle and group structures are explained in more detail below. All coordinates have the unit of [pixel].

### Video data structure

The video data structure contains 3 fields:
1. frameRate: The frame rate of the video in frames per second.
2. duration: The duration fo the video in seconds.
3. filename: The full filename of the video file.

### Rectangle data structure

The video data structure contains 4 fields:
1. angle: The angle in degrees.
2. extent: The extent of the rectangle. A structure containing the fields (xMin, xMax, yMin & yMax)
3. lines: The lines making up the rectangle. A structure array with 4 structures each of which has 2 fields (the x-coordinates an the y-coordinates)
4. points: The points that mark the opposite corner points of the rectangle. A structure array with 2 structures each of which has 2 fields (the x-coordinate an the y-coordinate)

### Groups data structure

The groups data structure is a structure array with 2 structures each containing the shoulder rotation data per group. Each structure has 2 fields:
1. name: The group name
2. shoulders: A cell array whereby every row holds the data for each analysis step. The first column contains the frame number. The seconds column the number of pedestrians which marked shoulders. The third column contains a Nx4 matrix whereby N is the number of pedestrians with marked shoulders (i.e. the number in the second column). The columns of the matrix contain the following data [x-coord left shoulder, y-coord left shoulder, x-coord right shoulder, y-coord right shoulder]


