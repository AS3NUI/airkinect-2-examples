# AIRKinect - Examples

AIRKinect Extension is a Native Extension for use with Adobe AIR 3.0. AIRKinect allows AIR developers to tap into the rich experience of the Microsoft Kinect and push interactivity to a new level.

##Linking AIRKinect to your project


All you need is the ane file matching your driver. If you are using the MS SDK, you will need [airkinect-2-core-mssdk.ane](https://github.com/AS3NUI/airkinect-2-core/raw/master/bin/airkinect-2-core-mssdk.ane), if you are using OpenNI, you will need [airkinect-2-core-openni.ane](https://github.com/AS3NUI/airkinect-2-core/raw/master/bin/airkinect-2-core-openni.ane).

Once you have the correct file, you will need to link it to your AIR project:

###Flash Builder 4.6


1. Right click on your AIR for desktop project and choose properties.
2. Select Actionscript build path > Library path and click on Add SWC… Select the ane file you just downloaded.
3. In that same window, choose Native Extensions and click on Add ANE… Select that same ane file.
4. Select Actionscript Build Packaging > Native extensions. Check the checkbox next to the native extension. Ignore the warning that says the extension isn't used.

###Flash CS6


1. Go the File > Actionscript settings.
2. On the Library Path tab, click on the "Browse to a Native Extension (ANE)" button (button to the right of the SWC button)
3. Choose the ane file you just downloaded.

###IntelliJ IDEA


1. Right click on your module and choose "Open Module Settings".
2. Select the build configuration for your Module and open the Dependencies tab
3. Click on the plus (+) button on the bottom of that window and choose "New Library…"
4. Choose the ane file you just downloaded