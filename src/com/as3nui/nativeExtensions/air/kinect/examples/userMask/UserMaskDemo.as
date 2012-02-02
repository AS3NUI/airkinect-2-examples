package com.as3nui.nativeExtensions.air.kinect.examples.userMask
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class UserMaskDemo extends DemoBase
	{
		
		private static const TOP_LEFT:Point = new Point(0, 0);
		
		private var kinect:Kinect;
		private var depthImage:Bitmap;
		private var bmp:Bitmap;
		
		override protected function startDemoImplementation():void
		{
			trace("[UserMaskDemo] Start Demo");
			if(Kinect.isSupported())
			{
				trace("[UserMaskDemo] Start Kinect");
				
				depthImage = new Bitmap();
				addChild(depthImage);
				
				kinect = Kinect.getKinect();
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USER_MASK_IMAGE_UPDATE, userMaskImageUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.depthEnabled = true;
				config.depthShowUserColors = true;
				config.userMaskEnabled = true;
				
				bmp = new Bitmap(new BitmapData(config.userMaskWidth, config.userMaskHeight, true, 0));
				addChild(bmp);
				
				kinect.start(config);
			}
		}
		
		protected function depthImageUpdateHandler(event:CameraImageEvent):void
		{
			depthImage.bitmapData = event.imageData;
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[UserMaskDemo] Kinect Started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[UserMaskDemo] Kinect Stopped");
		}
		
		protected function userMaskImageUpdateHandler(event:UserEvent):void
		{
			//first user
			/*
			if(event.users.length > 0)
			{
				bmp.bitmapData = event.users[0].userMaskData;
			}
			*/
			
			//all users
			bmp.bitmapData.lock();
			bmp.bitmapData.fillRect(bmp.bitmapData.rect, 0);
			
			for each(var user:User in event.users)
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
			trace("[UserMaskDemo] Stop Demo");
			
			if(kinect != null)
			{
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
				kinect.removeEventListener(UserEvent.USER_MASK_IMAGE_UPDATE, userMaskImageUpdateHandler);
				kinect.stop();
			}
		}
		
		override protected function layout():void
		{
			trace("[UserMaskDemo] Layout");
			if(bmp != null)
			{
				bmp.x = (explicitWidth - bmp.width) * .5;
				bmp.y = (explicitHeight - bmp.height) * .5;
			}
		}
	}
}