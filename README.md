blog_in_cl
==========

Implementing a blog in Common Lisp. See http://roeim.net/vetle/docs/cl-webapp-intro/

Developed under SBCL.

Prerequisites
-------------

* hunchentoot
* html-template
* elephant

Build and Run
---------------

1. Clone the code

  ```
  git clone https://github.com/WaldonChen/blog_in_cl
  ```

2. Load the package with SBCL

  ```lisp
  (defun load-package (absolute-path package-sym)
    (let ((asdf:*central-registry*
            (append asdf:*central-registry* (list absolute-path))))
      (asdf:operate 'asdf:load-op package-sym)))

  (load-package #P"/absolute/path/of/blog_in_cl/" 'blog)
  ```

3. Start blog server

  ```lisp
  (blog:start-blog)
  ```
  Open http://localhost:8080/ in your web browser. You can stop the server with:

  ```lisp
  (blog:stop-blog)
  ```
