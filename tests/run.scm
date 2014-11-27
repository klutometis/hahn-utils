(use cock-utils
     test)

(test-assert (version<=? "0.0.2" "0.1.1"))
(test-assert (version<=? "1.2.3" "1.2.4"))
(test-assert (version<=? "1.2" "1.2.4"))
(test-assert (version<=? "1.2.3" "1.2.10"))
