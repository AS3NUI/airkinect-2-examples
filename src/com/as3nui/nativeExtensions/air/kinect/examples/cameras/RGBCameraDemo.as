package com.as3nui.nativeExtensions.air.kinect.examples.cameras
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.constants.Framework;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;

	public class RGBCameraDemo extends DemoBase
	{
		
		private var rgbBitmap:Bitmap;
		private var device:Kinect;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				device = Kinect.getDevice();
				
				rgbBitmap = new Bitmap();
				addChild(rgbBitmap);
				
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var settings:KinectSettings = new KinectSettings();
				settings.rgbEnabled = true;
				if(device.capabilities.framework == Framework.MSSDK)
				{
					settings.rgbResolution = CameraResolution.RESOLUTION_1280_960;
				}
				else
				{
					settings.rgbResolution = CameraResolution.RESOLUTION_640_480;
				}
				
				device.start(settings);
			}
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[RGBCameraDemo] device started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[RGBCameraDemo] device stopped");
		}
		
		override protected function stopDemoImplementation():void
		{
			if(device != null)
			{
				device.stop();
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
			}
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbBitmap.bitmapData = event.imageData;
			layout();
		}
		
		override protected function layout():void
		{
			rgbBitmap.x = (explicitWidth - rgbBitmap.width) * .5;
			rgbBitmap.y = (explicitHeight - rgbBitmap.height) * .5;
		}
	}
}