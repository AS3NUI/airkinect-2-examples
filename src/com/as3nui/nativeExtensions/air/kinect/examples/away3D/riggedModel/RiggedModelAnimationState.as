/**
 * Created with IntelliJ IDEA.
 * User: wouter
 * Date: 21/08/12
 * Time: 18:11
 * To change this template use File | Settings | File Templates.
 */
package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel {
import away3d.animators.IAnimator;
import away3d.animators.data.JointPose;
import away3d.animators.data.Skeleton;
import away3d.animators.data.SkeletonPose;
import away3d.animators.states.AnimationStateBase;
import away3d.animators.states.ISkeletonAnimationState;
import away3d.core.math.Quaternion;

import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.derschmale.data.ObjectPool;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.utils.Dictionary;

public class RiggedModelAnimationState extends AnimationStateBase implements ISkeletonAnimationState {

    private var _kinectUser:User;
    private var _jointMapping:Dictionary;
    private var _skeleton:Skeleton;

    private var _currentSkeletonPose:SkeletonPose;
    private var _kinectSkeletonPose:SkeletonPose;

    private var _globalWisdom:Vector.<Boolean>;
    private var _localPoses:Vector.<JointPose>;
    private var _bindPoses:Vector.<Matrix3D>;
    private var _bindPoseOrientationsOfTrackedJoints:Dictionary;
    private var _bindShoulderOrientation:Vector3D;
    private var _bindSpineOrientation:Vector3D;
    private var _trackingCenter:Vector3D;
    private var _quaternionPool:ObjectPool;
    private var _vector3DPool:ObjectPool;

    private var _rootLocalPose:JointPose;

    public function RiggedModelAnimationState(animator:IAnimator, node:RiggedModelAnimationNode) {
        super(animator, node);

        _kinectUser = node.kinectUser;
        _jointMapping = node.jointMapping;

        _quaternionPool = ObjectPool.getGlobalPool(Quaternion);
        _vector3DPool = ObjectPool.getGlobalPool(Vector3D);
        _trackingCenter = new Vector3D();
    }

    public function getSkeletonPose(skeleton:Skeleton):SkeletonPose {

        if (isNewSkeleton(skeleton)) {
            _skeleton = skeleton;
            initSkeleton();
            initBindPoseOrientations();
        }

        updatePose();

        return _currentSkeletonPose;
    }

    private function isNewSkeleton(skeleton:Skeleton):Boolean {
        return (_localPoses == null);
    }

    private function initSkeleton():void {
        var q1:Quaternion = Quaternion(_quaternionPool.alloc()),
                q2:Quaternion = Quaternion(_quaternionPool.alloc());
        var bind:Matrix3D = new Matrix3D();
        var parentBind:Matrix3D = new Matrix3D();

        _localPoses = new Vector.<JointPose>(_skeleton.numJoints, true);
        _globalWisdom = new Vector.<Boolean>(_skeleton.numJoints, true);
        _bindPoses = new Vector.<Matrix3D>(_skeleton.numJoints, true);

        _kinectSkeletonPose = new SkeletonPose();
        _kinectSkeletonPose.jointPoses = new Vector.<JointPose>(_skeleton.numJoints, true);

        _currentSkeletonPose = new SkeletonPose();
        _currentSkeletonPose.jointPoses = new Vector.<JointPose>(_skeleton.numJoints, true);

        for (var i:int = 0; i < _skeleton.numJoints; ++i) {
            var joint:away3d.animators.data.SkeletonJoint = _skeleton.joints[i];
            _localPoses[i] = new JointPose();

            _kinectSkeletonPose.jointPoses[i] = new JointPose();
            _kinectSkeletonPose.jointPoses[i].orientation = new Quaternion();
            _kinectSkeletonPose.jointPoses[i].translation = new Vector3D();

            _currentSkeletonPose.jointPoses[i] = new JointPose();
            _currentSkeletonPose.jointPoses[i].orientation = new Quaternion();
            _currentSkeletonPose.jointPoses[i].translation = new Vector3D();

            bind = new Matrix3D(joint.inverseBindPose);
            bind.invert();
            _bindPoses[i] = bind;

            _localPoses[i].orientation = new Quaternion();
            if (joint.parentIndex < 0) {
                _rootLocalPose = _localPoses[i];
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

    private function initBindPoseOrientations():void {
        _bindPoseOrientationsOfTrackedJoints = new Dictionary();

        _bindShoulderOrientation = new Vector3D();
        _bindSpineOrientation = new Vector3D();

        getSimpleBindOrientation(SkeletonJoint.RIGHT_SHOULDER, SkeletonJoint.LEFT_SHOULDER, _bindShoulderOrientation);
        getSimpleBindOrientation(SkeletonJoint.TORSO, SkeletonJoint.NECK, _bindSpineOrientation);

        getSimpleBindOrientation(SkeletonJoint.NECK, SkeletonJoint.HEAD);
        getSimpleBindOrientation(SkeletonJoint.LEFT_SHOULDER, SkeletonJoint.LEFT_ELBOW);
        getSimpleBindOrientation(SkeletonJoint.LEFT_ELBOW, SkeletonJoint.LEFT_HAND);
        getSimpleBindOrientation(SkeletonJoint.RIGHT_SHOULDER, SkeletonJoint.RIGHT_ELBOW);
        getSimpleBindOrientation(SkeletonJoint.RIGHT_ELBOW, SkeletonJoint.RIGHT_HAND);
        getSimpleBindOrientation(SkeletonJoint.LEFT_HIP, SkeletonJoint.LEFT_KNEE);
        getSimpleBindOrientation(SkeletonJoint.LEFT_KNEE, SkeletonJoint.LEFT_FOOT);
        getSimpleBindOrientation(SkeletonJoint.RIGHT_HIP, SkeletonJoint.RIGHT_KNEE);
        getSimpleBindOrientation(SkeletonJoint.RIGHT_KNEE, SkeletonJoint.RIGHT_FOOT);
    }

    private function getSimpleBindOrientation(sourceKinectJointName:String, targetKinectJointName:String, storeVec:Vector3D = null):void {
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

    private function updatePose():void {
        updateCentralPosition();
        updateTorso();
        updateSimpleJoint(SkeletonJoint.NECK, SkeletonJoint.HEAD);
        updateSimpleJoint(SkeletonJoint.LEFT_SHOULDER, SkeletonJoint.LEFT_ELBOW);
        updateSimpleJoint(SkeletonJoint.LEFT_ELBOW, SkeletonJoint.LEFT_HAND);
        updateSimpleJoint(SkeletonJoint.RIGHT_SHOULDER, SkeletonJoint.RIGHT_ELBOW);
        updateSimpleJoint(SkeletonJoint.RIGHT_ELBOW, SkeletonJoint.RIGHT_HAND);
        updateSimpleJoint(SkeletonJoint.LEFT_HIP, SkeletonJoint.LEFT_KNEE);
        updateSimpleJoint(SkeletonJoint.LEFT_KNEE, SkeletonJoint.LEFT_FOOT);
        updateSimpleJoint(SkeletonJoint.RIGHT_HIP, SkeletonJoint.RIGHT_KNEE);
        updateSimpleJoint(SkeletonJoint.RIGHT_KNEE, SkeletonJoint.RIGHT_FOOT);

        for each(var jointName:String in _kinectUser.skeletonJointNames) {
            var mapIndex:int = _jointMapping[jointName];
            if (mapIndex >= 0 && _kinectUser.getJointByName(jointName).positionConfidence < .5)
                _globalWisdom[mapIndex] = false;
        }

        var mtx:Matrix3D = new Matrix3D();
        var mtx2:Matrix3D = new Matrix3D();

        var globalPoses : Vector.<JointPose> = _kinectSkeletonPose.jointPoses;
        var globalJointPose : JointPose;
        var joints : Vector.<away3d.animators.data.SkeletonJoint> = _skeleton.joints;
        var len : uint = _currentSkeletonPose.numJointPoses;
        var parentIndex : int;
        var joint : away3d.animators.data.SkeletonJoint;

        if (globalPoses.length != len) globalPoses.length = len;

        for (var i : uint = 0; i < len; ++i) {
            joint = joints[i];
            parentIndex = joint.parentIndex;
            globalJointPose = globalPoses[i];
            var localPose:JointPose = _localPoses[i];

            if (parentIndex < 0) {
                globalJointPose.copyFrom(localPose);
            } else {
                var globalOrientation:Quaternion = globalJointPose.orientation;
                var globalTranslation:Vector3D = globalJointPose.translation;
                var localOrientation:Quaternion = localPose.orientation;
                var localTranslation:Vector3D = localPose.translation;

                var parentPose:JointPose = _kinectSkeletonPose.jointPoses[parentIndex];
                var parentOrientation:Quaternion = parentPose.orientation;
                var parentTranslation:Vector3D = parentPose.translation;

                parentPose.orientation.rotatePoint(localTranslation, globalTranslation);

                globalTranslation.x += parentTranslation.x;
                globalTranslation.y += parentTranslation.y;
                globalTranslation.z += parentTranslation.z;

                if (!_globalWisdom[i]) {
                    globalOrientation.multiply(parentOrientation, localOrientation);
                    globalOrientation.normalize();
                }
                else {
                    _bindPoses[i].copyToMatrix3D(mtx);
                    mtx.append(globalOrientation.toMatrix3D(mtx2));
                    globalOrientation.fromMatrix(mtx);
                }
            }

            _currentSkeletonPose.jointPoses[i].copyFrom(globalJointPose);
        }
    }

    private function getPosition(kinectSkeletonJoint:SkeletonJoint):Vector3D {
        return kinectSkeletonJoint.position.world.clone();
    }

    private function updateCentralPosition():void {
        var center:Vector3D = getPosition(_kinectUser.torso);
        var tr:Vector3D = _rootLocalPose.translation;
        var _posSmoothing:Number = .8;
        var invPosSmoothing:Number = 1 - _posSmoothing;

        var _trackScale:Number = .1;
        tr.x = tr.x + ((center.x - _trackingCenter.x) * _trackScale - tr.x) * invPosSmoothing;
        tr.y = tr.y + ((center.y - _trackingCenter.y) * _trackScale - tr.y) * invPosSmoothing;
        tr.z = tr.z + ((center.z - _trackingCenter.z) * _trackScale - tr.z) * invPosSmoothing;
    }

    private function updateTorso():void {
        var mapIndex:int = _jointMapping[SkeletonJoint.TORSO];
        if (mapIndex < 0) return;

        _globalWisdom[mapIndex] = true;

        var shoulderDir:Vector3D = getPosition(_kinectUser.leftShoulder).subtract(getPosition(_kinectUser.rightShoulder));
        shoulderDir.y = 0.0;
        shoulderDir.normalize();
        var axis:Vector3D = _bindShoulderOrientation.crossProduct(shoulderDir);
        var torsoYawRotation:Quaternion = Quaternion(_quaternionPool.alloc());
        torsoYawRotation.fromAxisAngle(axis, Math.acos(_bindShoulderOrientation.dotProduct(shoulderDir)));

        var pos1:Vector3D = getPosition(_kinectUser.neck);
        var pos2:Vector3D = getPosition(_kinectUser.torso);
        var spineDir:Vector3D = Vector3D(_vector3DPool.alloc());
        spineDir.x = 0.0;
        spineDir.y = pos1.y - pos2.y;
        spineDir.z = pos1.z - pos2.z;
        spineDir.normalize();
        axis = _bindSpineOrientation.crossProduct(spineDir);
        var torsoPitchRotation:Quaternion = Quaternion(_quaternionPool.alloc());
        torsoPitchRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));

        spineDir.x = pos1.x - pos2.x;
        spineDir.y = pos1.y - pos2.y;
        spineDir.z = 0;
        spineDir.normalize();
        axis = _bindSpineOrientation.crossProduct(spineDir);
        var torsoRollRotation:Quaternion = Quaternion(_quaternionPool.alloc());
        torsoRollRotation.fromAxisAngle(axis, Math.acos(_bindSpineOrientation.dotProduct(spineDir)));

        var temp:Quaternion = Quaternion(_quaternionPool.alloc());
        temp.multiply(torsoPitchRotation, torsoRollRotation);

        _kinectSkeletonPose.jointPoses[mapIndex].orientation.multiply(torsoYawRotation, temp);

        _quaternionPool.free(temp);
        _quaternionPool.free(torsoPitchRotation);
        _quaternionPool.free(torsoRollRotation);
        _quaternionPool.free(torsoYawRotation);
        _vector3DPool.free(spineDir);
    }

    private function updateSimpleJoint(sourceKinectJointName:String, targetKinectJointName:String):void {
        var bindDir:Vector3D, currDir:Vector3D, axis:Vector3D;
        var mapIndex:int = _jointMapping[sourceKinectJointName];
        var orientation:Quaternion;
        var sourceKinectJoint:SkeletonJoint = _kinectUser.getJointByName(sourceKinectJointName);
        var targetKinectJoint:SkeletonJoint = _kinectUser.getJointByName(targetKinectJointName);

        if (mapIndex < 0) return;

        currDir = getPosition(targetKinectJoint).subtract(getPosition(sourceKinectJoint));
        currDir.normalize();
        bindDir = _bindPoseOrientationsOfTrackedJoints[sourceKinectJointName];

        axis = bindDir.crossProduct(currDir);
        axis.normalize();

        _globalWisdom[mapIndex] = true;
        orientation = _kinectSkeletonPose.jointPoses[mapIndex].orientation;
        orientation.fromAxisAngle(axis, Math.acos(bindDir.dotProduct(currDir)));
    }
}
}
