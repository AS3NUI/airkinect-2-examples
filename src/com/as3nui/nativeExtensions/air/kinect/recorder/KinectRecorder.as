package com.as3nui.nativeExtensions.air.kinect.recorder
{
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.data.Serialize;
	import com.as3nui.nativeExtensions.air.kinect.data.UserFrame;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserFrameEvent;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.getTimer;

	public class KinectRecorder
	{
		
		private var _isRecording:Boolean;
		
		private var _kinect:Kinect;
		private var _recordingStartTime:int;
		
		private var _tempDirectory:File;
		private var _tempSettingsFile:File;
		private var _rgbTempDirectory:File;
		private var _depthTempDirectory:File;
		private var _userFrameTempDirectory:File;
		
		private var _exportDirectory:File;
		private var _exportSettingsFile:File;
		private var _exportRgbDirectory:File;
		private var _exportDepthDirectory:File;
		private var _exportUserFrameDirectory:File;
		
		public function KinectRecorder()
		{
		}
		
		public function startRecording(kinect:Kinect):void
		{
			if(!_isRecording)
			{
				_isRecording = true;
				
				Serialize.init();
				
				_recordingStartTime = getTimer();
				_kinect = kinect;
				
				_tempDirectory = File.createTempDirectory();
				
				trace("tmp dir", _tempDirectory.nativePath);
				
				_tempSettingsFile = _tempDirectory.resolvePath("settings.json");
				var settingsFileStream:FileStream = new FileStream();
				settingsFileStream.open(_tempSettingsFile, FileMode.WRITE);
				settingsFileStream.writeUTFBytes(JSON.stringify(_kinect.settings));
				settingsFileStream.close();
				
				_rgbTempDirectory = _tempDirectory.resolvePath("rgb");
				_rgbTempDirectory.createDirectory();
				
				_depthTempDirectory = _tempDirectory.resolvePath("depth");
				_depthTempDirectory.createDirectory();
				
				_userFrameTempDirectory = _tempDirectory.resolvePath("user");
				_userFrameTempDirectory.createDirectory();
				
				_kinect.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false, 0, true);
				_kinect.addEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false, 0, true);
				_kinect.addEventListener(UserFrameEvent.USER_FRAME_UPDATE, userFrameUpdateHandler, false, 0, true);
			}
		}
		
		public function stopRecording():void
		{
			if(_isRecording)
			{
				_isRecording = false;
				if(_kinect)
				{
					_kinect.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, rgbHandler, false);
					_kinect.removeEventListener(CameraImageEvent.DEPTH_IMAGE_UPDATE, depthHandler, false);
					_kinect.removeEventListener(UserFrameEvent.USER_FRAME_UPDATE, userFrameUpdateHandler, false);
				}
				
				//save the recording
				askForExportLocation();
			}
		}
		
		private function askForExportLocation():void
		{
			_exportDirectory = File.documentsDirectory;
			_exportDirectory.addEventListener(Event.SELECT, exportDirectorySelectHandler, false, 0, true);
			_exportDirectory.browseForDirectory("Where do you want to save the recording?");
		}
		
		protected function exportDirectorySelectHandler(event:Event):void
		{
			_exportDirectory.removeEventListener(Event.SELECT, exportDirectorySelectHandler, false);
			saveToExportLocation();
		}
		
		private function saveToExportLocation():void
		{
			copySettings();
			startAsyncRgbCopy();
		}
		
		private function copySettings():void
		{
			_exportSettingsFile = _exportDirectory.resolvePath("settings.json");
			_tempSettingsFile.copyTo(_exportSettingsFile, true);
		}
		
		private function startAsyncRgbCopy():void
		{
			_exportRgbDirectory = _exportDirectory.resolvePath("rgb");
			_rgbTempDirectory.addEventListener(Event.COMPLETE, asyncRgbCompleteHandler, false, 0, true);
			_rgbTempDirectory.copyToAsync(_exportRgbDirectory, true);
		}
		
		protected function asyncRgbCompleteHandler(event:Event):void
		{
			_rgbTempDirectory.removeEventListener(Event.COMPLETE, asyncRgbCompleteHandler, false);
			startAsyncDepthCopy();
		}
		
		private function startAsyncDepthCopy():void
		{
			_exportDepthDirectory = _exportDirectory.resolvePath("depth");
			_depthTempDirectory.addEventListener(Event.COMPLETE, asyncDepthCompleteHandler, false, 0, true);
			_depthTempDirectory.copyToAsync(_exportDepthDirectory, true);
		}
		
		protected function asyncDepthCompleteHandler(event:Event):void
		{
			_depthTempDirectory.removeEventListener(Event.COMPLETE, asyncDepthCompleteHandler, false);
			startAsyncUserFrameCopy()
		}
		
		private function startAsyncUserFrameCopy():void
		{
			_exportUserFrameDirectory = _exportDirectory.resolvePath("user");
			_userFrameTempDirectory.addEventListener(Event.COMPLETE, asyncUserFrameCompleteHandler, false, 0, true);
			_userFrameTempDirectory.copyToAsync(_exportUserFrameDirectory, true);
		}
		
		protected function asyncUserFrameCompleteHandler(event:Event):void
		{
			_userFrameTempDirectory.removeEventListener(Event.COMPLETE, asyncUserFrameCompleteHandler, false);
			removeTempDirectory();
			trace("save complete");
		}
		
		private function removeTempDirectory():void
		{
			_tempDirectory.deleteDirectory(true);
		}
		
		protected function rgbHandler(event:CameraImageEvent):void
		{
			writeImageFrame(_rgbTempDirectory, event.imageData);
		}
		
		protected function depthHandler(event:CameraImageEvent):void
		{
			writeImageFrame(_depthTempDirectory, event.imageData);
		}
		
		protected function userFrameUpdateHandler(event:UserFrameEvent):void
		{
			writeUserFrame(_userFrameTempDirectory, event.userFrame);
		}
		
		private function writeImageFrame(frameDirectory:File, bmpData:BitmapData):void
		{
			var time:int = getTimer() - _recordingStartTime;
			var frameFile:File = frameDirectory.resolvePath("" + time);
			var fileStream:FileStream = new FileStream();
			fileStream.open(frameFile, FileMode.WRITE);
			fileStream.writeInt(bmpData.width);
			fileStream.writeInt(bmpData.height);
			fileStream.writeBytes(bmpData.getPixels(bmpData.rect));
			fileStream.close();
		}
		
		private function writeUserFrame(frameDirectory:File, userFrame:UserFrame):void
		{
			var time:int = getTimer() - _recordingStartTime;
			var frameFile:File = frameDirectory.resolvePath("" + time);
			var fileStream:FileStream = new FileStream();
			fileStream.open(frameFile, FileMode.WRITE);
			fileStream.writeObject(userFrame);
			fileStream.close();
		}
	}
}