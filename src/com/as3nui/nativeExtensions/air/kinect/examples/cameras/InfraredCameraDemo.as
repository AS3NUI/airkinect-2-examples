package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.openni.OpenNIKinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.openni.events.OpenNICameraImageEvent;
	
	import flash.display.Bitmap;

	public class InfraredCameraDemo extends DemoBase
	{
		private var infraredBitmap:Bitmap;
		private var device:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				if(device.capabilities.hasInfraredSupport)
				{
					infraredBitmap = new Bitmap();
					addChild(infraredBitmap);
					
					device.addEventListener(OpenNICameraImageEvent.INFRARED_IMAGE_UPDATE, infraredImageUpdateHandler, false, 0, true);
					device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
					device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
					
					var config:OpenNIKinectSettings = new OpenNIKinectSettings();
					config.infraredEnabled = true;
					config.infraredResolution = CameraResolution.RESOLUTION_640_480;
					
					device.start(config);					
				}
			}
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[InfraredCameraDemo] device started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[InfraredCameraDemo] device stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.stop();
				device.removeEventListener(OpenNICameraImageEvent.INFRARED_IMAGE_UPDATE, infraredImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function infraredImageUpdateHandler(event:OpenNICameraImageEvent):void
		{
			infraredBitmap.bitmapData = event.imageData;
			layout();
		}
		
		override protected function layout():void
		{
			if(infraredBitmap){
				infraredBitmap.x = (explicitWidth - infraredBitmap.width) * .5;
				infraredBitmap.y = (explicitHeight - infraredBitmap.height) * .5;
			}
		}
	}
}