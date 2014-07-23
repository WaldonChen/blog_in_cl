;;;; package.lisp

(defpackage :blog
  (:use :cl
        :hunchentoot
        :elephant)
  (:shadowing-import-from :elephant
                          :pset-list
                          :persistent-metaclass
                          :get-instances-by-range
                          )
  (:export :start-blog
           :stop-blog))
