package com.as3nui.nativeExtensions.air.kinect.recorder
{
	import com.as3nui.nativeExtensions.air.kinect.bridge.ExtensionContextBridge;
	import com.as3nui.nativeExtensions.air.kinect.bridge.IContextBridge;
	import com.as3nui.nativeExtensions.air.kinect.data.DeviceCapabilities;
	import com.as3nui.nativeExtensions.air.kinect.data.PointCloudRegion;
	import com.as3nui.nativeExtensions.air.kinect.data.Serialize;
	import com.as3nui.nativeExtensions.air.kinect.data.UserFrame;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class KinectPlayerContextBridge extends EventDispatcher implements IContextBridge
	{
		
		private var _frameHelperSprite:Sprite;
		private var _playbackStartTime:int;
		private var _playbackDirectory:File;
		
		private var _rgbFramePlayer:ImageFramePlayer;
		private var _depthFramePlayer:ImageFramePlayer;
		private var _userFramePlayer:UserFramePlayer;
		
		public var playbackDirectoryUrl:String;
		
		public function KinectPlayerContextBridge(target:IEventDispatcher=null)
		{
			super(target);
			
			Serialize.init();
			
			_frameHelperSprite = new Sprite();
			
			_rgbFramePlayer = new ImageFramePlayer();
			_rgbFramePlayer.addEventListener(Event.CHANGE, rgbFrameChangeHandler, false, 0, true);
			
			_depthFramePlayer = new ImageFramePlayer();
			_depthFramePlayer.addEventListener(Event.CHANGE, depthFrameChangeHandler, false, 0, true);
			
			_userFramePlayer = new UserFramePlayer();
			_userFramePlayer.addEventListener(Event.CHANGE, userFrameChangeHandler, false, 0, true);
		}
		
		public function askToPlayRecording():void
		{
			_playbackDirectory = File.documentsDirectory;
			_playbackDirectory.addEventListener(Event.SELECT, playbackDirectorySelectHandler, false, 0, true);
			_playbackDirectory.browseForDirectory("Select the directory for playback");
		}
		
		protected function playbackDirectorySelectHandler(event:Event):void
		{
			trace("playing from", _playbackDirectory.nativePath);
			readPlaybackDirectory();
			playRecording();
		}
		
		protected function readPlaybackDirectory():void
		{
			_rgbFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("rgb"));
			_depthFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("depth"));
			_userFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("user"));
		}
		
		private function playRecording():void
		{
			_rgbFramePlayer.playRecording();
			_depthFramePlayer.playRecording();
			_userFramePlayer.playRecording();
			
			_playbackStartTime = getTimer();
			_frameHelperSprite.addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "status", ExtensionContextBridge.EXTENSION_EVENT_DEVICE_STARTED));
		}
		
		protected function rgbFrameChangeHandler(event:Event):void
		{
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "status", ExtensionContextBridge.EXTENSION_EVENT_RGB_FRAME_AVAILABLE));
		}
		
		protected function depthFrameChangeHandler(event:Event):void
		{
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "status", ExtensionContextBridge.EXTENSION_EVENT_DEPTH_FRAME_AVAILABLE));
		}
		
		protected function userFrameChangeHandler(event:Event):void
		{
			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, "status", ExtensionContextBridge.EXTENSION_EVENT_USER_FRAME_AVAILABLE));
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			var time:int = getTimer() - _playbackStartTime;
			
			_rgbFramePlayer.updateTime(time);
			_depthFramePlayer.updateTime(time);
			_userFramePlayer.updateTime(time);
			
			if(_rgbFramePlayer.isFinished && _depthFramePlayer.isFinished && _userFramePlayer.isFinished)
			{
				_playbackStartTime = getTimer();
				
				_rgbFramePlayer.stopPlaying();
				_depthFramePlayer.stopPlaying();
				_userFramePlayer.stopPlaying();
				
				_rgbFramePlayer.playRecording();
				_depthFramePlayer.playRecording();
				_userFramePlayer.playRecording();
			}
		}
		
		public function getDeviceCount():uint
		{
			return 1;
		}
		
		public function applicationStartup(framework:uint):void
		{
		}
		
		public function applicationShutdown():void
		{
		}
		
		public function getCapabilities(nr:uint):DeviceCapabilities
		{
			return null;
		}
		
		public function getCameraElevationAngle(nr:uint):int
		{
			return 0;
		}
		
		public function setCameraElevationAngle(nr:uint, value:int):void
		{
		}
		
		public function start(nr:uint):void
		{
			if(playbackDirectoryUrl != null)
			{
				_playbackDirectory = new File(playbackDirectoryUrl);
				trace(_playbackDirectory.nativePath);
				readPlaybackDirectory();
				playRecording();
			}
			else
			{
				askToPlayRecording();
			}
		}
		
		public function stop(nr:uint):void
		{
			_frameHelperSprite.removeEventListener(Event.ENTER_FRAME, enterFrameHandler, false);
		}
		
		public function setRgbEnabled(nr:uint, rgbEnabled:Boolean):void
		{
		}
		
		public function setRgbMode(nr:uint, width:uint, height:uint, mirrored:Boolean):void
		{
		}
		
		public function setDepthEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setDepthMode(nr:uint, width:uint, height:uint, mirrored:Boolean):void
		{
		}
		
		public function setDepthShowUserColors(nr:uint, showUserColors:Boolean):void
		{
		}
		
		public function setNearModeEnabled(nr:uint, enableNearMode:Boolean):void
		{
		}
		
		public function setPointcloudEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setPointcloudMode(nr:uint, width:uint, height:uint, mirrored:Boolean, density:uint, includeRgb:Boolean):void
		{
		}
		
		public function setPointCloudRegions(nr:uint, pointCloudRegions:Vector.<PointCloudRegion>):void
		{
		}
		
		public function setUserEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setUserMode(nr:uint, mirrored:Boolean):void
		{
		}
		
		public function setSkeletonEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setSkeletonMode(nr:uint, mirrored:Boolean, seatedSkeletonEnabled:Boolean, chooseSkeletons:Boolean):void
		{
		}
		
		public function chooseSkeletons(nr:uint, trackingIds:Vector.<uint>):void
		{
		}
		
		public function setUserMaskEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setUserMaskMode(nr:uint, width:uint, height:uint, mirrored:Boolean):void
		{
		}
		
		public function getDepthFrame(nr:uint, imageBytes:ByteArray):void
		{
			imageBytes.clear();
			imageBytes.writeBytes(_depthFramePlayer.imageBytes);
			imageBytes.position = 0;
		}
		
		public function getRgbFrame(nr:uint, imageBytes:ByteArray):void
		{
			imageBytes.clear();
			imageBytes.writeBytes(_rgbFramePlayer.imageBytes);
			imageBytes.position = 0;
		}
		
		public function getPointcloudFrame(nr:uint, bytes:ByteArray, regions:Vector.<PointCloudRegion>):void
		{
		}
		
		public function getUserMaskFrame(nr:uint, userID:uint, maskByteArray:ByteArray):void
		{
		}
		
		public function getUserFrame(nr:uint):UserFrame
		{
			return _userFramePlayer.userFrame;
		}
		
		public function setInfraredEnabled(nr:uint, enabled:Boolean):void
		{
		}
		
		public function setInfraredMode(nr:uint, width:uint, height:uint, mirrored:Boolean):void
		{
		}
		
		public function getInfraredFrame(nr:uint, imageBytes:ByteArray):void
		{
		}
	}
}

import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.as3nui.nativeExtensions.air.kinect.data.UserFrame;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

internal class FramePlayer extends EventDispatcher
{
	protected var _currentFrameTime:int;
	protected var _currentFrameTimeIndex:int;
	protected var _numFrames:int;
	protected var _frameTimes:Vector.<int>;
	protected var _framesDirectory:File;
	protected var _isPlaying:Boolean;
	protected var _isFinished:Boolean;
	
	public function get isFinished():Boolean
	{
		return _isFinished;
	}
	
	public function readFrameNrsFromPlaybackDirectory(framesDirectory:File):void
	{
		_framesDirectory = framesDirectory;
		_frameTimes = getFramesFromDirectory(framesDirectory);
		_numFrames = _frameTimes.length;
	}
	
	private function getFramesFromDirectory(directory:File):Vector.<int>
	{
		var frames:Vector.<int> = new Vector.<int>();
		if(directory.exists)
		{
			var files:Array = directory.getDirectoryListing();
			for each(var f:File in files)
			{
				frames.push(f.name);
			}
			//sort frame numerically
			frames = frames.sort(Array.NUMERIC);
		}
		return frames;
	}
	
	public function playRecording():void
	{
		if(!_isPlaying)
		{
			_isPlaying = true;
			_isFinished = false;
			_currentFrameTime = 0;
			_currentFrameTimeIndex = 0;
		}
	}
	
	public function stopPlaying():void
	{
		if(_isPlaying)
		{
			_isPlaying = false;
		}
	}
	
	public function updateTime(time:int):void
	{
		if(_numFrames > 0)
		{
			var frameTimeDiff:int = time - _currentFrameTime;
			var newFrameTimeIndex:uint = _currentFrameTimeIndex;
			//rgb frame
			for(var i:int = _currentFrameTimeIndex; i < _numFrames; i++)
			{
				var timeDiff:int = time - _frameTimes[i];
				if(timeDiff > 0 && timeDiff <= frameTimeDiff)
				{
					frameTimeDiff = timeDiff;
					newFrameTimeIndex = i;
				}
				else
				{
					break;
				}
			}
			if(newFrameTimeIndex != _currentFrameTimeIndex)
			{
				_currentFrameTimeIndex = newFrameTimeIndex;
				_currentFrameTime = _frameTimes[_currentFrameTimeIndex];
				handleNewFrame();
				
				if((_currentFrameTimeIndex + 1) >= _numFrames)
				{
					_isFinished = true;
					dispatchEvent(new Event(Event.COMPLETE));
				}
			}
		}
		else
		{
			_isFinished = true;
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
	
	protected function handleNewFrame():void
	{
	}
}

internal class UserFramePlayer extends FramePlayer
{
	
	protected var _userFrame:UserFrame;
	
	public function get userFrame():UserFrame
	{
		return _userFrame;
	}
	
	override protected function handleNewFrame():void
	{
		var fs:FileStream = new FileStream();
		fs.open(_framesDirectory.resolvePath("" + _currentFrameTime), FileMode.READ);
		
		var o:Object = fs.readObject();
		if(o is UserFrame)
		{
			_userFrame = o as UserFrame;
		}
		else
		{
			_userFrame = new UserFrame();
			_userFrame.frameNumber = o.frameNumber;
			_userFrame.timestamp = o.timestamp;
			_userFrame.users = Vector.<User>([]);
		}
		/*
		_userFrame = new UserFrame();
		_userFrame.frameNumber = o.frameNumber;
		_userFrame.timestamp = o.timestamp;
		_userFrame.users = deserializeUsers(o.users);
		*/
		
		dispatchEvent(new Event(Event.CHANGE));
	}
}

internal class ImageFramePlayer extends FramePlayer
{
	
	protected var _imageBytes:ByteArray;
	
	public function get imageBytes():ByteArray
	{
		return _imageBytes;
	}
	
	override protected function handleNewFrame():void
	{
		var fs:FileStream = new FileStream();
		fs.open(_framesDirectory.resolvePath("" + _currentFrameTime), FileMode.READ);
		_imageBytes = new ByteArray();
		var width:int = fs.readInt();
		var height:int = fs.readInt();
		fs.readBytes(_imageBytes);
		dispatchEvent(new Event(Event.CHANGE));
	}
	
}