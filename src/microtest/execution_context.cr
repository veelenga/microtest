module Microtest
  class ExecutionContext
    getter results : Array(TestResult)
    getter reporters : Array(Reporter)
    getter suites : Array(Test.class)
    getter random_seed : UInt32
    getter random : Random
    getter aborting_exception : HookException? = nil

    def initialize(@reporters : Array(Reporter), @suites, @random_seed : UInt32 = Random.new_seed)
      @results = [] of TestResult
      @random = Random.new(@random_seed)
    end

    def errors : Array(TestFailure)
      results.compact_map(&.as?(TestFailure))
    end

    def errors?
      errors.any?
    end

    def aborted?
      !!aborting_exception
    end

    def skips
      results.compact_map(&.as?(TestSkip))
    end

    def started
      reporters.each(&.started(self))
    end

    def finished
      reporters.each(&.finished(self))
    end

    def test_suite(cls)
      reporters.each(&.suite_started(self, cls.name))
      yield # FIXME
      reporters.each(&.suite_finished(self, cls.name))
    end

    def test_case(name)
      yield # FIXME
    end

    def record_result(result : TestResult)
      @results << result
      @reporters.each(&.report(result))
      # FIXME
    end

    def abort!(exception : HookException)
      @reporters.each(&.abort(self, exception))
      @aborting_exception = exception
    end

    def total_tests
      suites.map(&.test_methods.size).sum
    end

    def total_success
      results.count(&.as?(TestSuccess))
    end

    def total_failure
      results.count(&.as?(TestFailure))
    end

    def total_skip
      results.count(&.as?(TestSkip))
    end
  end
end
