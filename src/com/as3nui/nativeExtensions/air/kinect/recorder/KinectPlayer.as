package com.as3nui.nativeExtensions.air.kinect.recorder
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.mssdk.MSKinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.frameworks.openni.OpenNIKinectSettings;
	
	public class KinectPlayer extends Kinect
	{
		
		public var playbackDirectoryUrl:String;
		
		public function KinectPlayer()
		{
			super(0);
		}
		
		override protected function createContextBridge():void
		{
			contextBridge = new KinectPlayerContextBridge();
		}
		
		override protected function initSettings():void
		{
			super.initSettings();
			(contextBridge as KinectPlayerContextBridge).playbackDirectoryUrl = playbackDirectoryUrl;
		}
		
		override protected function parseSettings(deviceSettings:Object):KinectSettings
		{
			if(deviceSettings is MSKinectSettings)
				return deviceSettings as MSKinectSettings;
			if(deviceSettings is OpenNIKinectSettings)
				return deviceSettings as OpenNIKinectSettings;
			if(deviceSettings is KinectSettings)
				return deviceSettings as KinectSettings;
			return KinectSettings.create(deviceSettings);
		}
	}
}