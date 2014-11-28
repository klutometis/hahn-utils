(use cock-utils
     test)

(test-assert (version<=? "0.1" "0.3.4"))
(test-assert (not (version<=? "0.3.4" "0.1")))
(test-assert (version<=? "0.0.2" "0.1.1"))
(test-assert (not (version<=?  "0.1.1" "0.0.2")))
(test-assert (version<=? "1.2.3" "1.2.4"))
(test-assert (not (version<=? "1.2.4" "1.2.3")))
(test-assert (version<=? "1.2" "1.2.4"))
(test-assert (not (version<=? "1.2.4" "1.2")))
(test-assert (version<=? "1.2.3" "1.2.10"))
(test-assert (not (version<=? "1.2.10" "1.2.3")))
