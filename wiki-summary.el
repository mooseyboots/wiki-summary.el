;;; wiki-summary.el --- View Wikipedia summaries in Emacs easily

;; Copright (C) 2015 Danny Gratzer
;; Author: Danny Gratzer
;; URL: https://github.com/jozefg/wiki-summary.el
;; Keywords: wikipedia, utility
;; Package-Requires: ((emacs "24"))
;; Version: 0.1

(require 'url)
(require 'json)

(defun wiki-summary/make-api-query (s)
  "Given a wiki page title, generate the url for the API call
   to get the page info"
  (let ((pre "https://en.wikipedia.org/w/api.php?continue=&action=query&titles=")
        (post "&prop=extracts&exintro=&explaintext=&format=json&redirects")
        (term (replace-regexp-in-string " " "_" s)))
    (concat pre term post)))

(defun wiki-summary/extract-summary-from-response (resp)
  "Given the JSON reponse from the webpage, grab the summary as a string"
  (let* ((query (plist-get resp 'query))
         (pages (plist-get query 'pages))
         (info (cadr pages))
         (summary (plist-get info 'extract)))
    (if (not summary)
        (message "No page found!")
      summary)))

(defun wiki-summary/format-summary-in-buffer (summary)
  "Given a summary, stick it in the *wiki-summary* buffer and display the buffer"
  (let ((buf (generate-new-buffer "*wiki-summary*")))
    (with-current-buffer buf
      (princ summary buf)
      (fill-paragraph)
      (beginning-of-buffer)
      (text-mode)
      (read-only-mode))
    (display-buffer buf)))

(defun wiki-summary (s)
  "Return the wikipedia page's summary for a term"
  (interactive
   (list
    (read-string (concat
                  "Wikipedia Article"
                  (if (thing-at-point 'word)
                      (concat "(" (thing-at-point 'word) ")")
                    "")
                  ": ")
                 nil
                 nil
                 (thing-at-point 'word))))
  (save-excursion
    (url-retrieve (wiki-summary/make-api-query s)
       (lambda (events)
         (message "") ; Clear the annoying minibuffer display
         (goto-char url-http-end-of-headers)
         (let ((json-object-type 'plist)
               (json-key-type 'symbol)
               (json-array-type 'vector))
           (let* ((result (json-read))
                  (summary (wiki-summary/extract-summary-from-response result)))
             (wiki-summary/format-summary-in-buffer summary)))))))

(provide 'wiki-summary)
