;;;; blog.lisp

(in-package :blog)

;;; "blog" goes here. Hacks and glory await!

(defclass blog-post ()
  ((title :initarg :title
          :accessor title)
   (body :initarg :body
         :accessor body)
   (timestamp :initarg  :timestamp
              :accessor timestamp
              :initform (get-universal-time)
              :index t)
   (url-part :initarg :url-part
             :accessor url-part
             :initform nil
             :index t))
  (:metaclass persistent-metaclass))

(defmethod initialize-instance :after ((obj blog-post) &key)
  "If :url-part wasn't non-nil when making the instance,
generate it automatically."
  (cond ((eq nil (url-part obj))
         (setf (url-part obj) (make-url-part (title obj))))))

(defun make-url-part (title)
  "Generate a url-part from a title."
  (string-downcase
    (delete-if #'(lambda (x) (not (or (alphanumericp x) (char= #\- x))))
               (substitute #\- #\Space title))))

(defun dump-all-post ()
  (loop for blog-post in (nreverse (get-instances-by-range
                                     'blog-post 'timestamp nil nil))
        collect (list :title (title blog-post)
                      :body (body blog-post)
                      :url-part (url-part blog-post))))

(defun generate-index-page ()
  "Generate the index page showing all the blog posts."
  (with-output-to-string (stream)
    (let ((html-template:*string-modifier* #'identity))
      (html-template:fill-and-print-template
        #P"index.tmpl"
        (list :blog-posts
              (loop for blog-post in (nreverse
                                       (get-instances-by-range
                                         'blog-post 'timestamp nil nil))
                    collect (list :title (title blog-post)
                                  :body (body blog-post)
                                  :url-part (url-part blog-post))))
        :stream stream))))

(defun generate-blog-post-page (template)
  (let ((url-part (hunchentoot:query-string*)))
    ; Create a stream that will give us a string
    (with-output-to-string (stream)
      (let ((blog-post (get-instance-by-value 'blog-post 'url-part url-part))
            (html-template:*string-modifier* #'identity))
        (html-template:fill-and-print-template
          template
          (list :title (title blog-post)
                :body (body blog-post)
                :url-part (url-part blog-post))
          :stream stream)))))

(defvar *username* "admin")
(defvar *password* "admin")

(defmacro with-http-authentication (&rest body)
  `(multiple-value-bind
     (username password)
     (authorization)
     (cond ((and (string= username *username*)
                 (string= password *password*))
            ,@body)
           (t (require-authorization "blog")))))

(defun view-page-url-of (url-part)
  (concatenate 'string "/view/?" url-part))

(defun view-blog-post-page ()
  (generate-blog-post-page #P"post.tmpl"))

(defun save-blog-post ()
  "Read POST data and modify blog post"
  (let ((blog-post
          (get-instance-by-value 'blog-post 'url-part
                                 (hunchentoot:query-string*))))
    (setf (title blog-post) (hunchentoot:post-parameter "title"))
    (setf (body blog-post) (hunchentoot:post-parameter "body"))
    (setf (url-part blog-post) (make-url-part (title blog-post)))
    (redirect (view-page-url-of (url-part blog-post)))))

(defun edit-blog-post()
  (with-http-authentication
    (cond ((eq (hunchentoot:request-method*) :GET)
           (generate-blog-post-page #P"post-form.tmpl"))
          ((eq (hunchentoot:request-method*) :POST)
           (save-blog-post)))))

(defun create-blog-post ()
  (with-http-authentication
   (cond ((eq (request-method*) :GET)
         (with-output-to-string (stream)
           (html-template:fill-and-print-template
             #P"post-form.tmpl" nil
             :stream stream)))
        ((eq (request-method*) :POST)
         (save-new-blog-post)))))

(defun save-new-blog-post ()
  (let ((blog-post (make-instance
                     'blog-post
                     :title (post-parameter "title")
                     :body (post-parameter "body"))))
    (redirect (view-page-url-of (url-part blog-post)))))

(setq hunchentoot:*dispatch-table*
      (list (create-regex-dispatcher "^/$" 'generate-index-page)
            (create-regex-dispatcher "^/view/$" 'view-blog-post-page)
            (create-regex-dispatcher "^/edit/$" 'edit-blog-post)
            (create-regex-dispatcher "^/create/$" 'create-blog-post)))

(defun start-blog ()
  ; Open the store where our data is stored
  (defvar *elephant-store*
    (open-store '(:clsql (:sqlite3 "./blog.db"))))
  ; Serving the web page
  (defvar *ht-server*
    (start (make-instance 'hunchentoot:easy-acceptor :port 8080))))

(defun stop-blog ()
  (cond ((boundp '*ht-server*)
         (stop *ht-server*))
        ((boundp '*elephant-store*)
         (close-store *elephant-store*))))

#|
(defun 404-dispatcher (request)
  '404-page)

(defun 404-page ()
  "404 is here!")

(push-end-new '404-dispatcher *dispatch-table*)  ;; make sure the
dispatcher is at the end of the *dispatch-table*
|#
