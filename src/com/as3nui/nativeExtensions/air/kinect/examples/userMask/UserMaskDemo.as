package com.as3nui.nativeExtensions.air.kinect.examples.userMask
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	import com.bit101.components.CheckBox;
	import com.bit101.utils.MinimalConfigurator;

	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class UserMaskDemo extends DemoBase
	{
		
		private static const TOP_LEFT:Point = new Point(0, 0);
		
		private var device:Kinect;
		private var depthImage:Bitmap;

		public var chk_depthMirror:CheckBox;
		public var chk_userMaskMirror:CheckBox;

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

				device = Kinect.getDevice();
				
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthImageUpdateHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_ADDED, usersAddedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_REMOVED, usersRemovedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_MASK_IMAGE_UPDATE, usersMaskImageUpdateHandler, false, 0, true);

				var settings:KinectSettings = new KinectSettings();
				settings.depthEnabled = true;
				settings.depthResolution = CameraResolution.RESOLUTION_320_240;

				settings.userMaskEnabled = true;
				settings.userMaskResolution = CameraResolution.RESOLUTION_320_240;

				initUI(settings);

				device.start(settings);
			}
		}

		private function initUI(deviceSettings:KinectSettings):void {
			var config:MinimalConfigurator = new MinimalConfigurator(this);

			var mainLayout:XML = <comps>
				<Window title="Point Cloud Settings" id="wnd_settings" x="10" y="50" width="200" height="150">
					<VBox x="10" y="10" spacing="10">
						<CheckBox label="Depth Mirror" id="chk_depthMirror" event="click:onClick"/>
						<CheckBox label="User Mask Mirror" id="chk_userMaskMirror" event="click:onClick"/>
					</VBox>
				</Window>
			</comps>;

			config.parseXML(mainLayout);

			chk_depthMirror.selected = deviceSettings.depthMirrored;
			chk_userMaskMirror.selected = deviceSettings.userMaskMirrored;

		}

		public function onClick(event:MouseEvent):void {
			switch(event.target){
				case chk_depthMirror:
					device.setDepthMirror(chk_depthMirror.selected);
					break;
				case chk_userMaskMirror:
					device.setUserMaskMirror(chk_userMaskMirror.selected);
					break;
			}
		}

		protected function usersAddedHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = new Bitmap();
				userMasks.push(bmp);
				userMaskDictionary[user.userID] = bmp;
				addChild(bmp);
			}
			layout();
		}
		
		protected function usersRemovedHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = userMaskDictionary[user.userID];
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
				delete userMaskDictionary[user.userID];
			}
			layout();
		}
		
		protected function depthImageUpdateHandler(event:CameraImageEvent):void
		{
			depthImage.bitmapData = event.imageData;
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void
		{
			trace("[UserMaskDemo] Kinect Started");
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void
		{
			trace("[UserMaskDemo] Kinect Stopped");
		}
		
		protected function usersMaskImageUpdateHandler(event:UserEvent):void
		{
			for each(var user:User in event.users)
			{
				var bmp:Bitmap = userMaskDictionary[user.userID];
				if(bmp != null)
				{
					bmp.bitmapData = user.userMaskData;
				}
			}
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[UserMaskDemo] Stop Demo");
			if(device != null)
			{
				for each(var user:User in device.users)
				{
					if(userMaskDictionary[user.userID] != null && userMaskDictionary[user.userID].bitmapData != null)
					{
						userMaskDictionary[user.userID].bitmapData.dispose();
					}
					delete userMaskDictionary[user.userID];
				}
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				device.removeEventListener(UserEvent.USERS_MASK_IMAGE_UPDATE, usersMaskImageUpdateHandler);
				device.stop();
			}
		}
		
		override protected function layout():void
		{
			trace("[UserMaskDemo] Layout");
			var xPos:uint = explicitWidth * .5;
			var yPos:uint = 240;

			depthImage.x = xPos - (depthImage.width/2);

			for each(var bmp:Bitmap in userMasks)
			{
				bmp.x = xPos - (bmp.width/2);
				bmp.y = yPos;
			}
		}
	}
}