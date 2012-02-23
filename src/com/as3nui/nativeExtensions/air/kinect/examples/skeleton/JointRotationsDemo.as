package com.as3nui.nativeExtensions.air.kinect.examples.skeleton
{
	import com.as3nui.nativeExtensions.air.kinect.Device;
	import com.as3nui.nativeExtensions.air.kinect.DeviceSettings;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Vector3D;

	public class JointRotationsDemo extends DemoBase
	{
		
		private var device:Device;
		
		private var rgbImage:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		private var skeletonContainer:Sprite;
		
		override protected function startDemoImplementation():void
		{
			trace("[JointRotationsDemo] Start Demo");
			if(Device.isSupported())
			{
				
				rgbImage = new Bitmap();
				addChild(rgbImage);
				
				rgbSkeletonContainer = new Sprite();
				addChild(rgbSkeletonContainer);
				
				skeletonContainer = new Sprite();
				addChild(skeletonContainer);
				
				device = Device.getDeviceByOS();
				
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler, false, 0, true);
				
				var settings:DeviceSettings = new DeviceSettings();
				settings.skeletonEnabled = true;
				settings.rgbEnabled = true;
				
				device.start(settings);
				
				addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			}
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			rgbSkeletonContainer.graphics.clear();
			skeletonContainer.graphics.clear();
			
			var joint:SkeletonJoint;
			var rotationVector:Vector3D;
			var centerX:uint = explicitWidth * .5;
			var centerY:uint = explicitHeight * .5;
			var drawX:uint = centerX;
			var drawY:uint = centerY;
			
			for each(var user:User in device.usersWithSkeleton)
			{
				if(user.hasSkeleton)
				{
					
					for each(joint in user.skeletonJoints)
					{
						//rgb overlay
						rgbSkeletonContainer.graphics.beginFill(0xFF0000);
						rgbSkeletonContainer.graphics.drawCircle(joint.rgbPosition.x, joint.rgbPosition.y, 5);
						rgbSkeletonContainer.graphics.endFill();
					}
					
					//draw bones according to joint orientation (z rotation = flash rotation)
					skeletonContainer.graphics.lineStyle(3, 0xFF0000);
					
					//
					// LEFT ARMS
					//
					
					skeletonContainer.graphics.moveTo(centerX, centerY);
					drawX = centerX;
					drawY = centerY;
					
					drawX = drawX + Math.cos(user.leftShoulder.orientation.z) * 100;
					drawY = drawY + Math.sin(user.leftShoulder.orientation.z) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					drawX = drawX + Math.cos(user.leftElbow.orientation.z) * 100;
					drawY = drawY + Math.sin(user.leftElbow.orientation.z) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					//
					// RIGHT ARMS
					//
					skeletonContainer.graphics.moveTo(centerX, centerY);
					drawX = centerX;
					drawY = centerY;
					
					drawX = drawX + Math.cos(user.rightShoulder.orientation.z + Math.PI) * 100;
					drawY = drawY + Math.sin(user.rightShoulder.orientation.z + Math.PI) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
					
					drawX = drawX + Math.cos(user.rightElbow.orientation.z + Math.PI) * 100;
					drawY = drawY + Math.sin(user.rightElbow.orientation.z + Math.PI) * 100;
					
					skeletonContainer.graphics.lineTo(drawX, drawY);
				}
			}
		}
		
		protected function rgbImageUpdateHandler(event:CameraImageEvent):void
		{
			rgbImage.bitmapData = event.imageData;
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[JointRotationsDemo] Stop Demo");
			if(device != null)
			{
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbImageUpdateHandler);
				device.stop();
			}
		}
	}
}