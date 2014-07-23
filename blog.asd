;;;; blog.asd

(asdf:defsystem #:blog
  :serial t
  :description "A simple blog"
  :author "Waldon Chen <waldonchen@gmail.com>"
  :license "license..."
  :depends-on (:html-template :hunchentoot :elephant)
  :components ((:file "package")
               (:file "blog")))
