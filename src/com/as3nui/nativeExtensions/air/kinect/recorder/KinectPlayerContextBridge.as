package com.as3nui.nativeExtensions.air.kinect.recorder
{
	import com.as3nui.nativeExtensions.air.kinect.bridge.ExtensionContextBridge;
	import com.as3nui.nativeExtensions.air.kinect.bridge.IContextBridge;
	import com.as3nui.nativeExtensions.air.kinect.data.DeviceCapabilities;
	import com.as3nui.nativeExtensions.air.kinect.data.PointCloudRegion;
	import com.as3nui.nativeExtensions.air.kinect.data.UserFrame;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	public class KinectPlayerContextBridge extends EventDispatcher implements IContextBridge
	{
		
		private var _frameHelperSprite:Sprite;
		private var _playbackStartTime:int;
		private var _playbackDirectory:File;
		
		private var _rgbFramePlayer:ImageFramePlayer;
		private var _depthFramePlayer:ImageFramePlayer;
		private var _userFramePlayer:UserFramePlayer;
		
		public function KinectPlayerContextBridge(target:IEventDispatcher=null)
		{
			super(target);
			
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
			_rgbFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("rgb"));
			_depthFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("depth"));
			_userFramePlayer.readFrameNrsFromPlaybackDirectory(_playbackDirectory.resolvePath("user"));
			playRecording();
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
			askToPlayRecording();
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
		
		public function setDepthEnableNearMode(nr:uint, enableNearMode:Boolean):void
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
		
		public function getSkeletonJointNameIndices(nr:uint):Dictionary
		{
			var skeletonJointNameIndices:Dictionary = new Dictionary();
			/*
			skeletonJointNameIndices['waist'] = 0;
			skeletonJointNameIndices['torso'] = 1;
			skeletonJointNameIndices['neck'] = 2;
			skeletonJointNameIndices['head'] = 3;
			skeletonJointNameIndices['left_shoulder'] = 4;
			skeletonJointNameIndices['left_elbow'] = 5;
			skeletonJointNameIndices['left_wrist'] = 6;
			skeletonJointNameIndices['left_hand'] = 7;
			skeletonJointNameIndices['right_shoulder'] = 8;
			skeletonJointNameIndices['right_elbow'] = 9;
			skeletonJointNameIndices['right_wrist'] = 10;
			skeletonJointNameIndices['right_hand'] = 11;
			skeletonJointNameIndices['left_hip'] = 12;
			skeletonJointNameIndices['left_knee'] = 13;
			skeletonJointNameIndices['left_ankle'] = 14;
			skeletonJointNameIndices['left_foot'] = 15;
			skeletonJointNameIndices['right_hip'] = 16;
			skeletonJointNameIndices['right_knee'] = 17;
			skeletonJointNameIndices['right_ankle'] = 18;
			skeletonJointNameIndices['right_foot'] = 19;
			*/
			skeletonJointNameIndices['torso'] = 0;
			skeletonJointNameIndices['neck'] = 1;
			skeletonJointNameIndices['head'] = 2;
			skeletonJointNameIndices['left_shoulder'] = 3;
			skeletonJointNameIndices['left_elbow'] = 4;
			skeletonJointNameIndices['left_hand'] = 5;
			skeletonJointNameIndices['right_shoulder'] = 6;
			skeletonJointNameIndices['right_elbow'] = 7;
			skeletonJointNameIndices['right_hand'] = 8;
			skeletonJointNameIndices['left_hip'] = 9;
			skeletonJointNameIndices['left_knee'] = 10;
			skeletonJointNameIndices['left_foot'] = 11;
			skeletonJointNameIndices['right_hip'] = 12;
			skeletonJointNameIndices['right_knee'] = 13;
			skeletonJointNameIndices['right_foot'] = 14;
			return skeletonJointNameIndices;
		}
		
		public function getSkeletonJointNames(nr:uint):Vector.<String>
		{
			/*
			return Vector.<String>([
				'waist',
				'torso',
				'neck',
				'head',
				'left_shoulder',
				'left_elbow',
				'left_wrist',
				'left_hand',
				'right_shoulder',
				'right_elbow',
				'right_wrist',
				'right_hand',
				'left_hip',
				'left_knee',
				'left_ankle',
				'left_foot',
				'right_hip',
				'right_knee',
				'right_ankle',
				'right_foot'
			]);*/
			return Vector.<String>([
				'torso',
				'neck',
				'head',
				'left_shoulder',
				'left_elbow',
				'left_hand',
				'right_shoulder',
				'right_elbow',
				'right_hand',
				'left_hip',
				'left_knee',
				'left_foot',
				'right_hip',
				'right_knee',
				'right_foot'
			]);
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
		
		public function setSkeletonMode(nr:uint, mirrored:Boolean):void
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

import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.as3nui.nativeExtensions.air.kinect.data.UserFrame;

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.utils.ByteArray;
import flash.utils.Endian;

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
		
		_userFrame = new UserFrame(o.frameNumber, o.timestamp, deserializeUsers(o.users));
		
		dispatchEvent(new Event(Event.CHANGE));
	}
	
	private function deserializeUsers(userObjects:Vector.<Object>):Vector.<User>
	{
		var users:Vector.<User> = new Vector.<User>();
		
		var numUsers:int = userObjects.length;
		for(var i:int = 0; i < numUsers; i++)
		{
			var userObject:Object = userObjects[i];
			var numJoints:int = (userObject.skeletonJoints != null) ? userObject.skeletonJoints.length  : 0;
			var skeletonJoints:Vector.<SkeletonJoint> = new Vector.<SkeletonJoint>();
			for(var j:int = 0; j < numJoints; j++)
			{
				var jointObject:Object = userObject.skeletonJoints[j];
				var joint:SkeletonJoint = new SkeletonJoint(
					jointObject.name, 
					deserializeVector3D(jointObject.position),
					deserializeVector3D(jointObject.positionRelative), 
					jointObject.positionConfidence, 
					deserializeMatrix3D(jointObject.absoluteOrientationMatrix), 
					deserializeVector3D(jointObject.absoluteOrientationQuaternion), 
					deserializeMatrix3D(jointObject.hierarchicalOrientationMatrix), 
					deserializeVector3D(jointObject.hierarchicalOrientationQuaternion), 
					jointObject.orientationConfidence, 
					deserializePoint(jointObject.rgbPosition), 
					deserializePoint(jointObject.rgbRelativePosition), 
					deserializePoint(jointObject.depthPosition), 
					deserializePoint(jointObject.depthRelativePosition));
				skeletonJoints.push(joint);
			}
			
			var user:User = new User(
				userObject.framework,
				userObject.userID, 
				userObject.trackingID, 
				deserializeVector3D(userObject.position), 
				deserializeVector3D(userObject.positionRelative), 
				deserializePoint(userObject.rgbPosition), 
				deserializePoint(userObject.rgbRelativePosition), 
				deserializePoint(userObject.depthPosition), 
				deserializePoint(userObject.depthRelativePosition), 
				userObject.hasSkeleton, 
				skeletonJoints);
			users.push(user);
		}
		
		return users;
	}
	
	private function deserializePoint(o:Object):Point
	{
		return new Point(o.x, o.y);
	}
	
	private function deserializeVector3D(o:Object):Vector3D
	{
		return new Vector3D(o.x, o.y, o.z, o.w);
	}
	
	private function deserializeMatrix3D(o:Object):Matrix3D
	{
		return new Matrix3D(o.rawData);
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