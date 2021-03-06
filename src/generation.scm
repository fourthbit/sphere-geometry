;;; Copyright (c) 2010 by Álvaro Castro-Castilla, All Rights Reserved.
;;; Licensed under the GPLv3 license, see LICENSE file for full description.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Geometry generation procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(declare (standard-bindings)
         (extended-bindings)
         (block))

(import (srfi 1-lists)
        (base debugging functional lists syntax)
        (math exact inexact)
        bounding-box
        kernel)

;-------------------------------------------------------------------------------
; Point generation
;-------------------------------------------------------------------------------

;;; Generate inexact random point

(define (~generate.random-point)
  (make-point (random-real)
              (random-real)))

;;; Generate exact random point

(define (generate.random-point)
  (make-point (inexact->exact (random-real))
              (inexact->exact (random-real))))

;;; Point between two points

(define (generate.point/two-points pa pb alpha)
  (vect2+
   pa
   (vect2:*scalar (point&point->direction pa pb)
                  alpha)))

;;; Random point between two points

(define (~generate.random-point/two-points pa pb)
  (generate.point/two-points pa pb (random-exact)))

;;; Generate regular point mesh

(define (generate.point-mesh-centered bb limits-offset offset-x offset-y #!optional point-modifier)
  (let* ((obox (vect2+ (make-point limits-offset limits-offset) (bbox-lefttop bb)))
         (o-x (vect2-x obox))
         (o-y (vect2-y obox))
         (ebox (vect2- (bbox-rightbottom bb) (make-point limits-offset limits-offset)))
         (e-x (vect2-x ebox))
         (e-y (vect2-y ebox))
         (size (vect2- (bbox:size-segment bb) (vect2:*scalar (make-vect2 limits-offset limits-offset) 2)))
         (size-x (vect2-x size))
         (size-y (vect2-y size)))
    (let ((start (make-point            ; center the mesh
                  (+ o-x
                     (/ (* (~decimal-part (/ size-x offset-x))
                           offset-x)
                        2))
                  (+ o-y
                     (/ (* (~decimal-part (/ size-y offset-y))
                           offset-y)
                        2))))
          (modifier (if point-modifier point-modifier (lambda (p) p))))
      (unfold (lambda (p) (> (point-y p) e-y))
              values
              (lambda (p) (if (> (+ offset-x (point-x p)) e-x)
                         (modifier (make-point (point-x start)
                                               (+ offset-y (point-y p))))
                         (modifier (make-point (+ offset-x (point-x p))
                                               (point-y p)))))
              start))))

;;; Return a random point that is inside a given pseq

(define (~generate.random-point-inside pseq)
  (define (gen a b)
    (aif p
         (curry pseq:point-inside? pseq)  
         (make-point (random-real/range (point-x a) (point-x b))
                     (random-real/range (point-y a) (point-y b)))
         p
         (gen a b)))
  (let ((bounding-box (pseq:bbox pseq)))
    (gen
     (bbox-lefttop bounding-box)
     (bbox-rightbottom bounding-box))))

;;; Return a random point that is inside a given pseq, with a minimal separation
;;; between points

(define (~generate.random-points/separation N pseq min-dist)
                                        ; TODO: OPTIMIZE, A way would be dividing the space
  (define (respects-distances? p plis)
    (every (lambda (p-in-plis) (< min-dist (~distance.point-point p p-in-plis))) plis))
  (define (gen n plis)
    (aif p
         (lambda (p) (respects-distances? p plis))
         (~generate.random-point-inside pseq)
         (if (>= n N)
             (cons p plis)
             (gen (add1 n) (cons p plis)))
         (gen n plis)))
  (gen 0 '()))

;-------------------------------------------------------------------------------
; Direction generation
;-------------------------------------------------------------------------------

;;; Generate inexact random direction

(define (~generate.random-direction)
  (make-direction (random-real)
                  (random-real)))

;;; Generate exact random direction

(define (generate.random-direction)
  (make-direction (inexact->exact (random-real))
                  (inexact->exact (random-real))))

;-------------------------------------------------------------------------------
; Line generation
;-------------------------------------------------------------------------------

;;; Generates 2 values: the two parallels to the given one at a specific distance

(define (generate.parallels-at-distance line distance)
  (let ((perp (vect2:*scalar
               (vect2:inexact->exact (vect2:~normalize
                                      (direction:perpendicular (line->direction line))))
               (inexact->exact distance))))
    (values (translate.line line perp)
            (translate.line line (vect2:symmetric perp)))))

