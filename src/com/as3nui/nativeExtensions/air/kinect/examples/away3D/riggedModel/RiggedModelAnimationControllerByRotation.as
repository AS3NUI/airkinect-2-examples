package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel
{
	import away3d.animators.data.SkeletonAnimation;
	import away3d.animators.data.SkeletonAnimationState;
	import away3d.animators.skeleton.JointPose;
	import away3d.animators.skeleton.Skeleton;
	import away3d.animators.skeleton.SkeletonJoint;
	import away3d.arcane;
	import away3d.core.math.Quaternion;
	
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.derschmale.data.ObjectPool;
	import com.derschmale.openni.XnSkeletonJoint;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	// http://groups.google.com/group/openni-dev/browse_thread/thread/9119214f36a28c8f
	
	use namespace arcane;
	
	public class RiggedModelAnimationControllerByRotation extends RiggedModelAnimationController
	{
		private static const NUM_TRACKED_JOINTS : int = 15;
		
		private var _jointMapping : Vector.<Number>;
		private var _skeleton : away3d.animators.skeleton.Skeleton;
		private var _globalMatrices : Vector.<Matrix3D>;
		private var _globalWisdom : Vector.<Boolean>;
		private var _localPoses : Vector.<JointPose>;
		private var _globalPoses : Vector.<JointPose>;
		private var _positionConfidences : Vector.<Number>;
		private var _bindPoses : Vector.<Matrix3D>;
		private var _bindPoseOrientations : Vector.<Vector3D>;
		private var _bindShoulderOrientation : Vector3D;
		private var _bindSpineOrientation : Vector3D;
		private var _jointSmoothing : Number = .1;
		private var _posSmoothing : Number = .8;
		private var _trackingCenter : Vector3D;
		private var _trackScale : Number = .1;
		private var _quaternionPool:ObjectPool;
		private var _vector3DPool:ObjectPool;
		private var _skeletonAnimationState : SkeletonAnimationState;
		
		public function RiggedModelAnimationControllerByRotation(jointMapping : Vector.<Number>, target : SkeletonAnimationState)
		{
			super();
			_quaternionPool = ObjectPool.getGlobalPool(Quaternion);
			_vector3DPool = ObjectPool.getGlobalPool(Vector3D);
			_jointMapping = jointMapping;
			
			_trackingCenter = new Vector3D();
			_positionConfidences = new Vector.<Number>(NUM_TRACKED_JOINTS, true);
			_skeletonAnimationState = target;
			
			SkeletonAnimationState(target).arcane::globalInput = true;
			
			initSkeleton();
			initBindPoseOrientations();
			
			start();
		}
		
		override protected function updateAnimation(realDT : Number, scaledDT : Number) : void
		{
			if(kinectUser != null)
			{
				updatePose();
			}
		}
		
		private function initSkeleton() : void
		{
			var joint : away3d.animators.skeleton.SkeletonJoint;
			var q1 : Quaternion = Quaternion(_quaternionPool.alloc()),
				q2 : Quaternion = Quaternion(_quaternionPool.alloc());
			var bind : Matrix3D = new Matrix3D();
			var parentBind : Matrix3D = new Matrix3D();
			
			_skeleton = SkeletonAnimation(_skeletonAnimationState.animation).skeleton;
			
			_localPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
			_globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
			_bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			_globalMatrices = new Vector.<Matrix3D>(_skeleton.numJoints, true);
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i) {
				// if index is in joint map, we know its global orientation
				joint = _skeleton.joints[i];
				_localPoses[i] = new JointPose();
				_globalPoses[i] = new JointPose();
				_globalPoses[i].orientation = new Quaternion();
				_globalPoses[i].translation = new Vector3D();
				bind = new Matrix3D(joint.inverseBindPose);
				bind.invert();
				_bindPoses[i] = bind;
				
				_localPoses[i].orientation = new Quaternion();
				if (joint.parentIndex < 0) {
					_localPoses[i].orientation.fromMatrix(bind);
					_localPoses[i].translation = bind.position;
				}
				else {
					parentBind.rawData = _skeleton.joints[joint.parentIndex].inverseBindPose;
					
					q1.fromMatrix(parentBind);
					q1.normalize();
					q2.fromMatrix(bind);
					q2.normalize();
					_localPoses[i].orientation.multiply(q1, q2);
					_localPoses[i].translation = parentBind.transformVector(bind.position);
				}
			}
			
			_quaternionPool.free(q1);
			_quaternionPool.free(q2);
		}
		
		private function initBindPoseOrientations() : void
		{
			_bindPoseOrientations = new Vector.<Vector3D>(NUM_TRACKED_JOINTS, true);
			
			_bindShoulderOrientation = new Vector3D();
			_bindSpineOrientation = new Vector3D();
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.RIGHT_SHOULDER, _bindShoulderOrientation);
			getSimpleBindOrientation(XnSkeletonJoint.TORSO, XnSkeletonJoint.NECK, _bindSpineOrientation);
			
			getSimpleBindOrientation(XnSkeletonJoint.NECK, XnSkeletonJoint.HEAD);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_SHOULDER, XnSkeletonJoint.LEFT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_ELBOW, XnSkeletonJoint.LEFT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_SHOULDER, XnSkeletonJoint.RIGHT_ELBOW);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_ELBOW, XnSkeletonJoint.RIGHT_HAND);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_HIP, XnSkeletonJoint.LEFT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.LEFT_KNEE, XnSkeletonJoint.LEFT_FOOT);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_HIP, XnSkeletonJoint.RIGHT_KNEE);
			getSimpleBindOrientation(XnSkeletonJoint.RIGHT_KNEE, XnSkeletonJoint.RIGHT_FOOT);
		}
		
		private function getSimpleBindOrientation(src : int, tgt : int, storeVec : Vector3D = null) : void
		{
			var pos1 : Vector3D;
			var pos2 : Vector3D;
			var mapIndex1 : int = _jointMapping[src];
			var mapIndex2 : int = _jointMapping[tgt];
			var mtx : Matrix3D = new Matrix3D();
			
			if (mapIndex1 < 0 || mapIndex2 < 0) return;
			
			pos1 = _bindPoses[mapIndex1].position;
			pos2 = _bindPoses[mapIndex2].position;
			
			if (!storeVec)
				(_bindPoseOrientations[src] = pos2.subtract(pos1)).normalize();
			else {
				storeVec.x = pos2.x - pos1.x;
				storeVec.y = pos2.y - pos1.y;
				storeVec.z = pos2.z - pos1.z;
				storeVec.normalize();
			}
		}
		
		private function updatePose() : void
		{
			setPositionConfidences();
			updateCentralPosition();
			updateSimpleJoint(XnSkeletonJoint.TORSO, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.TORSO);
			updateSimpleJoint(XnSkeletonJoint.NECK, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.NECK);
			updateSimpleJoint(XnSkeletonJoint.LEFT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_SHOULDER);
			updateSimpleJoint(XnSkeletonJoint.LEFT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_ELBOW);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_SHOULDER, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_SHOULDER);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_ELBOW, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_ELBOW);
			updateSimpleJoint(XnSkeletonJoint.LEFT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_HIP);
			updateSimpleJoint(XnSkeletonJoint.LEFT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.LEFT_KNEE);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_HIP, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_HIP);
			updateSimpleJoint(XnSkeletonJoint.RIGHT_KNEE, com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint.RIGHT_KNEE);
			
			for (var i : int = 0; i < NUM_TRACKED_JOINTS; ++i) {
				var mapIndex : int = _jointMapping[i];
				if (mapIndex >= 0 && _positionConfidences[i] < .5)
					_globalWisdom[mapIndex] = false;
			}
			
			updateMatrices();
		}
		
		private function setPositionConfidences() : void
		{
			_positionConfidences[XnSkeletonJoint.HEAD] = kinectUser.head.positionConfidence;
			_positionConfidences[XnSkeletonJoint.NECK] = kinectUser.neck.positionConfidence;
			_positionConfidences[XnSkeletonJoint.TORSO] = kinectUser.torso.positionConfidence;
			
			_positionConfidences[XnSkeletonJoint.LEFT_SHOULDER] = kinectUser.leftShoulder.positionConfidence;
			_positionConfidences[XnSkeletonJoint.LEFT_ELBOW] = kinectUser.leftElbow.positionConfidence;
			_positionConfidences[XnSkeletonJoint.LEFT_HAND] = kinectUser.leftHand.positionConfidence;
			
			_positionConfidences[XnSkeletonJoint.RIGHT_SHOULDER] = kinectUser.rightShoulder.positionConfidence;
			_positionConfidences[XnSkeletonJoint.RIGHT_ELBOW] = kinectUser.rightElbow.positionConfidence;
			_positionConfidences[XnSkeletonJoint.RIGHT_HAND] = kinectUser.rightHand.positionConfidence;
			
			_positionConfidences[XnSkeletonJoint.LEFT_HIP] = kinectUser.leftHip.positionConfidence;
			_positionConfidences[XnSkeletonJoint.LEFT_KNEE] = kinectUser.leftKnee.positionConfidence;
			_positionConfidences[XnSkeletonJoint.LEFT_FOOT] = kinectUser.leftFoot.positionConfidence;
			
			_positionConfidences[XnSkeletonJoint.RIGHT_HIP] = kinectUser.rightHip.positionConfidence;
			_positionConfidences[XnSkeletonJoint.RIGHT_KNEE] = kinectUser.rightKnee.positionConfidence;
			_positionConfidences[XnSkeletonJoint.RIGHT_FOOT] = kinectUser.rightFoot.positionConfidence;
		}
		
		private function updateCentralPosition() : void
		{
			var center : Vector3D = kinectUser.position;
			var tr : Vector3D = _localPoses[0].translation;
			var invPosSmoothing : Number = 1 - _posSmoothing;
			
			tr.x = tr.x + ((center.x - _trackingCenter.x) * _trackScale - tr.x) * invPosSmoothing;
			tr.y = tr.y + ((center.y - _trackingCenter.y) * _trackScale - tr.y) * invPosSmoothing;
			tr.z = tr.z + ((center.z - _trackingCenter.z) * _trackScale - tr.z) * invPosSmoothing;
		}
		
		private function updateSimpleJoint(srcJoint:int, kinectSkeletonJointName:String) : void
		{
			var mapIndex : int = _jointMapping[srcJoint];
			if (mapIndex < 0) return;
			_globalWisdom[mapIndex] = true;
			
			var orientation:Quaternion = getBoneOrientationFromKinectJoint(kinectUser.getJointByName(kinectSkeletonJointName));
			
			var initialBindPose:Vector3D = _bindPoseOrientations[srcJoint];
			if(initialBindPose != null)
			{
				//todo: take the initial pose into account (otherwise non-T-posed models don't work)
			}
			
			_globalPoses[mapIndex].orientation = orientation;
		}
		
		private function getBoneOrientationFromKinectJoint(joint:com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint):Quaternion
		{
			var q:Quaternion = new Quaternion();
			q.fromEulerAngles(joint.orientation.x, joint.orientation.y, joint.orientation.z);
			return q;
		}
		
		private function updateMatrices() : void
		{
			var j : int;
			var raw : Vector.<Number>;
			var joint : away3d.animators.skeleton.SkeletonJoint;
			var mtx : Matrix3D = new Matrix3D();
			var mtx2 : Matrix3D = new Matrix3D();
			var parentIndex : int;
			var globalPose : JointPose, localPose : JointPose, parentPose : JointPose;
			var globalOrientation : Quaternion, localOrientation : Quaternion, parentOrientation : Quaternion;
			var globalTranslation : Vector3D, localTranslation : Vector3D, parentTranslation : Vector3D;
			// todo: check if globalMatrices is correct (was: jointMatrices)
			var jointMatrices : Vector.<Number> = SkeletonAnimationState(_skeletonAnimationState).globalMatrices;
			
			for (var i : int = 0; i < _skeleton.numJoints; ++i) {
				joint = _skeleton.joints[i];
				parentIndex = joint.parentIndex;
				globalPose = _globalPoses[i];
				localPose = _localPoses[i];
				
				if (parentIndex < 0)
					globalPose.copyFrom(localPose);
				else {
					globalOrientation = globalPose.orientation;
					globalTranslation = globalPose.translation;
					localOrientation = localPose.orientation;
					localTranslation = localPose.translation;
					
					parentPose = _globalPoses[parentIndex];
					parentOrientation = parentPose.orientation;
					parentTranslation = parentPose.translation;
					parentPose.orientation.rotatePoint(localTranslation, globalTranslation);
					globalTranslation.x += parentTranslation.x;
					globalTranslation.y += parentTranslation.y;
					globalTranslation.z += parentTranslation.z;
					
					if (!_globalWisdom[i]) {
						globalOrientation.multiply(parentOrientation, localOrientation);
						globalOrientation.normalize();
					}
					else {
						_bindPoses[i].copyToMatrix3D(mtx)
						mtx.append(globalOrientation.toMatrix3D(mtx2));
						globalOrientation.fromMatrix(mtx);
					}
				}
				
				mtx.rawData = joint.inverseBindPose;
				mtx.append(globalPose.toMatrix3D(mtx2));
				raw = mtx.rawData;
				
				var smInv : Number = 1 - _jointSmoothing;
				
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[0] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[4] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[8] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[12] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[1] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[5] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[9] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[13] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[2] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[6] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[10] * smInv;
				++j;
				jointMatrices[j] = jointMatrices[j] * _jointSmoothing + raw[14] * smInv;
				++j;
			}
			
			SkeletonAnimationState(_skeletonAnimationState).invalidateState();
			SkeletonAnimationState(_skeletonAnimationState).arcane::validateGlobalMatrices();
		}
	}
}