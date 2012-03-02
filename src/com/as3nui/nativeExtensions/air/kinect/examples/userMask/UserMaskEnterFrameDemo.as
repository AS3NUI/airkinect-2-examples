package com.as3nui.nativeExtensions.air.kinect.examples.userMask
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class UserMaskEnterFrameDemo extends DemoBase
	{
		
		private static const TOP_LEFT:Point = new Point(0, 0);
		private var kinect:Kinect;
		private var bmp:Bitmap;
		
		override protected function startDemoImplementation():void
		{
			if(Kinect.isSupported())
			{
				kinect = Kinect.getDevice();
				
				kinect.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				
				var settings:KinectSettings = new KinectSettings();
				settings.userMaskEnabled = true;
				settings.userMaskResolution = CameraResolution.RESOLUTION_320_240;
				
				bmp = new Bitmap(new BitmapData(settings.userMaskResolution.x, settings.userMaskResolution.y, true, 0));
				addChild(bmp);
				
				kinect.start(settings);
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[UserMaskEnterFrameDemo] device stopped");
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[UserMaskEnterFrameDemo] device started");
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			bmp.bitmapData.lock();
			bmp.bitmapData.fillRect(bmp.bitmapData.rect, 0);
			for each(var user:User in kinect.users)
			{
				if(user.userMaskData != null)
				{
					bmp.bitmapData.copyPixels(user.userMaskData, user.userMaskData.rect, TOP_LEFT);
				}
			}
			bmp.bitmapData.unlock();
		}
		
		override protected function stopDemoImplementation():void
		{
			if(kinect != null)
			{
				kinect.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				kinect.stop();
			}
		}
	}
}