;; Auto-generated. Do not edit!


(when (boundp 'move::Move)
  (if (not (find-package "MOVE"))
    (make-package "MOVE"))
  (shadow 'Move (find-package "MOVE")))
(unless (find-package "MOVE::MOVE")
  (make-package "MOVE::MOVE"))

(in-package "ROS")
;;//! \htmlinclude Move.msg.html


(defclass move::Move
  :super ros::object
  :slots (_direction _power ))

(defmethod move::Move
  (:init
   (&key
    ((:direction __direction) "")
    ((:power __power) 0)
    )
   (send-super :init)
   (setq _direction (string __direction))
   (setq _power (round __power))
   self)
  (:direction
   (&optional __direction)
   (if __direction (setq _direction __direction)) _direction)
  (:power
   (&optional __power)
   (if __power (setq _power __power)) _power)
  (:serialization-length
   ()
   (+
    ;; string _direction
    4 (length _direction)
    ;; int32 _power
    4
    ))
  (:serialize
   (&optional strm)
   (let ((s (if strm strm
              (make-string-output-stream (send self :serialization-length)))))
     ;; string _direction
       (write-long (length _direction) s) (princ _direction s)
     ;; int32 _power
       (write-long _power s)
     ;;
     (if (null strm) (get-output-stream-string s))))
  (:deserialize
   (buf &optional (ptr- 0))
   ;; string _direction
     (let (n) (setq n (sys::peek buf ptr- :integer)) (incf ptr- 4) (setq _direction (subseq buf ptr- (+ ptr- n))) (incf ptr- n))
   ;; int32 _power
     (setq _power (sys::peek buf ptr- :integer)) (incf ptr- 4)
   ;;
   self)
  )

(setf (get move::Move :md5sum-) "efe20d682e9038d97b30d36a75eea378")
(setf (get move::Move :datatype-) "move/Move")
(setf (get move::Move :definition-)
      "string direction
int32 power
")



(provide :move/Move "efe20d682e9038d97b30d36a75eea378")


