require "../src/microtest"

include Microtest::DSL

COLOR_REGEX = %r{\e\[\d\d?m}

def uncolor(str)
  str.gsub(COLOR_REGEX, "")
end

class MicrotestJsonResult
  getter status : Process::Status
  getter json : JSON::Any

  def initialize(@status, @json)
  end

  def success?
    status.success? && json["success"] == true && json["aborted"] == false
  end
end

class MicrotestStdoutResult
  getter status : Process::Status
  getter stdout : String
  getter stderr : String

  def initialize(@status, @stdout, @stderr)
  end

  def success?
    status.success?
  end

  def to_s(io : IO)
    if success?
      io << stdout
    else
      io << stderr
      io << stdout
    end
  end
end

macro microtest_test(&block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!([
        Microtest::JsonSummaryReporter.new
      ] of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}], output: output)

  begin
    MicrotestJsonResult.new(s, JSON.parse(output.to_s))
  rescue e
    puts "Error parsing JSON:"
    p output.to_s
    raise e
  end
end

macro reporter_test(reporters, &block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!(#{reporters} of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new
  err = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}], output: output, error: err)

  MicrotestStdoutResult.new(s, output.to_s, err.to_s)
end

Microtest.run!
