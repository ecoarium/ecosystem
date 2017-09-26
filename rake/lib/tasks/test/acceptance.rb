require 'test/cucumber'

Test::Cucumber.test_type = :acceptance

Test::Cucumber.add_tag_argument(:acceptance_test, '~@manual')
Test::Cucumber.add_tag_argument(:acceptance_test, '~@broken-test')
Test::Cucumber.add_tag_argument(:acceptance_test, '~@backlog')

Test::Cucumber.add_tag_argument(:prepush_test, '@prepush')