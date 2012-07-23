package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.JointPose;
	import away3d.animators.data.Skeleton;
	import away3d.animators.data.SkeletonJoint;
	import away3d.animators.data.SkeletonPose;
	import away3d.animators.nodes.ISkeletonAnimationNode;
	import away3d.core.math.Quaternion;
	
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	public class RiggedModelAnimationNode extends EventDispatcher implements ISkeletonAnimationNode
	{
		
		private var _kinectUser:User;
		private var _jointMapping:Dictionary;
		private var _skeleton:Skeleton;
		
		private var _looping:Boolean;
		private var _rootDelta:Vector3D;
		
		private var _currentSkeletonPoseDirty:Boolean;
		private var _currentSkeletonPose:SkeletonPose;
		
		private var _skeletonBindPose:SkeletonPose;
		private var _skeletonKinectPose:SkeletonPose;
		
		private var _globalWisdom:Vector.<Boolean>;
		private var _bindPoses:Vector.<Matrix3D>;
		private var _bindPoseOrientationsOfTrackedJoints:Dictionary;
		private var _bindShoulderOrientation:Vector3D;
		private var _bindSpineOrientation:Vector3D;
		private var _rootJointIndex:int;
		
		public function RiggedModelAnimationNode(kinectUser:User, jointMapping:Dictionary)
		{
			_kinectUser = kinectUser;
			_jointMapping = jointMapping;
			_rootDelta = new Vector3D(0, 0, 0);
			_currentSkeletonPose = new SkeletonPose();
			_currentSkeletonPoseDirty = true;
		}
		
		public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
		{
			if(_currentSkeletonPoseDirty)
			{
				updateCurrentSkeletonPose(skeleton);
			}
			return _currentSkeletonPose;
		}
		
		public function get looping():Boolean
		{
			return _looping;
		}
		
		public function set looping(value:Boolean):void
		{
			_looping = value;
		}
		
		public function get rootDelta():Vector3D
		{
			return _rootDelta;
		}
		
		public function update(time:int):void
		{
			_currentSkeletonPoseDirty = true;
		}
		
		public function reset(time:int):void
		{
			trace("[RiggedModelAnimationNode] reset", time);
		}
		
		private function updateCurrentSkeletonPose(skeleton:Skeleton):void
		{
			_currentSkeletonPoseDirty = false;
			if(isNewSkeleton(skeleton))
			{
				_skeleton = skeleton;
				initSkeleton();
				initBindPoseOrientations();
			}
			updatePose();
		}
		
		private function isNewSkeleton(skeleton:Skeleton):Boolean
		{
			return (_skeletonBindPose == null);
		}
		
		private function initSkeleton():void
		{
			_skeletonBindPose = new SkeletonPose();
			_skeletonBindPose.jointPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			
			_skeletonKinectPose = new SkeletonPose();
			_skeletonKinectPose.jointPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			
			_globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
			_bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			for(var i:int = 0; i < _skeleton.numJoints; i++)
			{
				var joint:away3d.animators.data.SkeletonJoint = _skeleton.joints[i];
				
				_skeletonBindPose.jointPoses[i] = new JointPose();
				
				var bind:Matrix3D = new Matrix3D(joint.inverseBindPose);
				bind.invert();
				_bindPoses[i] = bind;
				
				_skeletonBindPose.jointPoses[i].orientation = new Quaternion();
				if (joint.parentIndex < 0)
				{
					_rootJointIndex = i;
					_skeletonBindPose.jointPoses[i].orientation.fromMatrix(bind);
					_skeletonBindPose.jointPoses[i].translation = bind.position;
				}
				else 
				{
					var parentBind:Matrix3D = new Matrix3D();
					parentBind.rawData = _skeleton.joints[joint.parentIndex].inverseBindPose;
					var q1:Quaternion = new Quaternion();
					var q2:Quaternion = new Quaternion();
					q1.fromMatrix(parentBind);
					q1.normalize();
					q2.fromMatrix(bind);
					q2.normalize();
					_skeletonBindPose.jointPoses[i].orientation.multiply(q1, q2);
					_skeletonBindPose.jointPoses[i].translation = parentBind.transformVector(bind.position);
				}
				
				_skeletonKinectPose.jointPoses[i] = new JointPose();
				_skeletonKinectPose.jointPoses[i].orientation.copyFrom(_skeletonBindPose.jointPoses[i].orientation);
				_skeletonKinectPose.jointPoses[i].translation.copyFrom(_skeletonBindPose.jointPoses[i].translation);
				
				_currentSkeletonPose.jointPoses[i] = new JointPose();
				_currentSkeletonPose.jointPoses[i].orientation.copyFrom(_skeletonBindPose.jointPoses[i].orientation);
				_currentSkeletonPose.jointPoses[i].translation.copyFrom(_skeletonBindPose.jointPoses[i].translation);
			}
		}
		
		private function initBindPoseOrientations():void
		{
			_bindPoseOrientationsOfTrackedJoints = new Dictionary();
			
			_bindShoulderOrientation = new Vector3D();
			_bindSpineOrientation = new Vector3D();
			
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, _bindShoulderOrientation);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, _bindSpineOrientation);
			
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			getSimpleBindOrientation(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT);
		}
		
		private function getSimpleBindOrientation(sourceKinectJointName:String, targetKinectJointName:String, storeVec:Vector3D = null):void
		{
			var pos1:Vector3D;
			var pos2:Vector3D;
			var mapIndex1:int = _jointMapping[sourceKinectJointName];
			var mapIndex2:int = _jointMapping[targetKinectJointName];
			var mtx:Matrix3D = new Matrix3D();
			
			if (mapIndex1 < 0 || mapIndex2 < 0) return;
			
			pos1 = _bindPoses[mapIndex1].position;
			pos2 = _bindPoses[mapIndex2].position;
			
			if (!storeVec)
				(_bindPoseOrientationsOfTrackedJoints[sourceKinectJointName] = pos2.subtract(pos1)).normalize();
			else {
				storeVec.x = pos2.x - pos1.x;
				storeVec.y = pos2.y - pos1.y;
				storeVec.z = pos2.z - pos1.z;
				storeVec.normalize();
			}
		}
		
		private function updatePose():void
		{
			updateCentralPosition();
			
			updateTorso();
			
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.HEAD);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HAND);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HAND);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_FOOT);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			updateSimpleJoint(com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_FOOT);
			
			updateGlobalWisdomFromPositionConfidences();
			
			var localSkeletonPose:SkeletonPose = _skeletonKinectPose;
			
			_currentSkeletonPose = localSkeletonPose;
		}
		
		private function getPosition(kinectSkeletonJoint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint):Vector3D
		{
			var p:Vector3D = new Vector3D();
			p.copyFrom(kinectSkeletonJoint.position.world);
			return p;
		}
		
		private function updateCentralPosition():void
		{
			var center:Vector3D = getPosition(_kinectUser.torso);
			center.scaleBy(.1);
			_skeletonKinectPose.jointPoses[_rootJointIndex].translation.copyFrom(center);
		}
		
		private function updateTorso():void
		{
			var mapIndex:int = _jointMapping[com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO];
			if (mapIndex < 0) return;
			
			_globalWisdom[mapIndex] = true;
			
			var torsoYawRotation:Quaternion = getTorsoYaw();
			var torsoPitchRotation:Quaternion = getTorsoPitch();
			var torsoRollRotation:Quaternion = getTorsoRoll();
			
			var temp:Quaternion = new Quaternion();
			temp.multiply(torsoPitchRotation, torsoRollRotation);
			
			_skeletonKinectPose.jointPoses[mapIndex].orientation.multiply(torsoYawRotation, temp);
		}
		
		private function getTorsoYaw():Quaternion
		{
			var shoulderDir:Vector3D = getPosition(_kinectUser.leftShoulder).subtract(getPosition(_kinectUser.rightShoulder));
			shoulderDir.y = 0.0;
			shoulderDir.normalize();
			var axis:Vector3D = _bindShoulderOrientation.crossProduct(shoulderDir);
			var torsoYawRotation:Quaternion = new Quaternion();;
			torsoYawRotation.fromAxisAngle(axis, Math.acos(_bindShoulderOrientation.dotProduct(shoulderDir)));
			return torsoYawRotation;
		}
		
		private function getTorsoPitch():Quaternion
		{
			var pos1:Vector3D = getPosition(_kinectUser.neck);
			var pos2:Vector3D = getPosition(_kinectUser.torso);
			var spineDir:Vector3D = new Vector3D();
			spineDir.x = 0.0;
			spineDir.y = pos1.y - pos2.y;
			spineDir.z = pos1.z - pos2.z;
			spineDir.normalize();
			var axis:Vector3D = _bindSpineOrientation.crossProduct(spineDir);
			var torsoPitchRotation:Quaternion = new Quaternion();
			torsoPitchRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));
			return torsoPitchRotation;
		}
		
		private function getTorsoRoll():Quaternion
		{
			var pos1:Vector3D = getPosition(_kinectUser.neck);
			var pos2:Vector3D = getPosition(_kinectUser.torso);
			var spineDir:Vector3D = new Vector3D();
			spineDir.x = pos1.x - pos2.x;
			spineDir.y = pos1.y - pos2.y;
			spineDir.z = 0;
			spineDir.normalize();
			var axis:Vector3D = _bindSpineOrientation.crossProduct(spineDir);
			var torsoRollRotation:Quaternion = new Quaternion();
			torsoRollRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));
			return torsoRollRotation;
		}
		
		private function updateSimpleJoint(sourceKinectJointName:String, targetKinectJointName:String):void
		{
			var mapIndex:int = _jointMapping[sourceKinectJointName];
			if (mapIndex < 0) return;
			
			var currDir:Vector3D = getPosition(_kinectUser.getJointByName(targetKinectJointName)).subtract(getPosition(_kinectUser.getJointByName(sourceKinectJointName)));
			currDir.normalize();
			
			var bindDir:Vector3D = _bindPoseOrientationsOfTrackedJoints[sourceKinectJointName].clone();
			
			var axis:Vector3D = bindDir.crossProduct(currDir);
			axis.normalize();
			
			_globalWisdom[mapIndex] = true;
			
			_skeletonKinectPose.jointPoses[mapIndex].orientation.fromAxisAngle(axis, Math.acos(bindDir.dotProduct(currDir)));
		}
		
		private function updateGlobalWisdomFromPositionConfidences():void
		{
			for each(var jointName:String in _kinectUser.skeletonJointNames)
			{
				var mapIndex:int = _jointMapping[jointName];
				if(mapIndex >= 0 && _kinectUser.getJointByName(jointName).positionConfidence < .5)
					_globalWisdom[mapIndex] = false;
			}
		}
	}
}