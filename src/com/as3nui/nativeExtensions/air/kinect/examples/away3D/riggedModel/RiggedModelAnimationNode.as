package com.as3nui.nativeExtensions.air.kinect.examples.away3D.riggedModel {
import away3d.animators.nodes.AnimationNodeBase;

import com.as3nui.nativeExtensions.air.kinect.data.User;

import flash.utils.Dictionary;

public class RiggedModelAnimationNode extends AnimationNodeBase {

    private var _kinectUser:User;

    private var _jointMapping:Dictionary;

    public function RiggedModelAnimationNode(kinectUser:User, jointMapping:Dictionary) {
        _kinectUser = kinectUser;
        _jointMapping = jointMapping;

        _stateClass = RiggedModelAnimationState;
    }

    public function get kinectUser():User {
        return _kinectUser;
    }

    public function get jointMapping():Dictionary {
        return _jointMapping;
    }
}
}