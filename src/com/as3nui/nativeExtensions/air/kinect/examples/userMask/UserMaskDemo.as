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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	public class UserMaskDemo extends DemoBase
	{
		
		private static const TOP_LEFT:Point = new Point(0, 0);
		
		private var kinect:Kinect;
		private var depthImage:Bitmap;
		
		private var userMasks:Vector.<Bitmap>;
		private var userMaskDictionary:Dictionary;
		
		override protected function startDemoImplementation():void
		{
			trace("[UserMaskDemo] Start Demo");
			if(Kinect.isSupported())
			{
				trace("[UserMaskDemo] Start Kinect");
				
				depthImage = new Bitmap();
				addChild(depthImage);
				
				userMasks = new Vector.<Bitmap>();
				userMaskDictionary = new Dictionary();
				
				kinect = Kinect.getKinect();
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_ADDED, usersAddedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_REMOVED, usersRemovedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_MASK_IMAGE_UPDATE, usersMaskImageUpdateHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.depthEnabled = true;
				config.depthShowUserColors = true;
				config.userMaskEnabled = true;
				
				kinect.start(config);
			}
		}
		
		protected function usersAddedHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = new Bitmap();
				userMasks.push(bmp);
				userMaskDictionary[user.trackingID] = bmp;
				addChild(bmp);
			}
			layout();
		}
		
		protected function usersRemovedHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = userMaskDictionary[user.trackingID];
				if(bmp != null)
				{
					if(bmp.parent != null)
					{
						bmp.parent.removeChild(bmp);
					}
					var index:int = userMasks.indexOf(bmp);
					if(index > -1)
					{
						userMasks.splice(index, 1);
					}
				}
				delete userMaskDictionary[user.trackingID];
			}
			layout();
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
		
		protected function usersMaskImageUpdateHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = userMaskDictionary[user.trackingID];
				if(bmp != null)
				{
					bmp.bitmapData = user.userMaskData;
				}
			}
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[UserMaskDemo] Stop Demo");
			if(kinect != null)
			{
				for each(var user:User in kinect.users)
				{
					if(userMaskDictionary[user.trackingID] != null)
					{
						userMaskDictionary[user.trackingID].bitmapData.dispose();
					}
					delete userMaskDictionary[user.trackingID];
				}
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
				kinect.removeEventListener(UserEvent.USERS_MASK_IMAGE_UPDATE, usersMaskImageUpdateHandler);
				kinect.stop();
			}
		}
		
		override protected function layout():void
		{
			trace("[UserMaskDemo] Layout");
			var xPos:uint = 0;
			var yPos:uint = 240;
			for each(var bmp:Bitmap in userMasks)
			{
				bmp.x = xPos;
				bmp.y = yPos;
				xPos += bmp.width;
			}
		}
	}
}