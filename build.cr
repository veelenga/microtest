require "ecr"
require "./src/microtest/version"

def render_html(cmd, target, title = "", bg = "black")
  full_cmd = <<-BASH
    #{cmd} | aha --#{bg} --title "#{title}" > #{target}.html
  BASH

  system(full_cmd)
end

def generate_image_from_html(file)
  system("sudo", ["docker", "run", "-v", "#{Dir.current}:/root/", "alpine-microtest", "/bin/sh", "-c", "wkhtmltoimage --width 800 /root/assets/#{file}.html /root/assets/#{file}.png"])
  system("rm", ["assets/#{file}.html"])
end

puts "Building"

system("sudo", ["docker", "build", ".", "-t", "alpine-microtest"])

render_html("crystal spec", "assets/spec")

class Readme
  def image(title, file)
    generate_image_from_html(file)
    # raise "Image does not exist: #{file}" unless File.exists?(file)
    "![#{title}](#{file}.png?raw=true)"
  end

  def generate_image_from_html(file)
    system("sudo", ["docker", "run", "-v", "#{Dir.current}:/root/", "alpine-microtest", "/bin/sh", "-c", "wkhtmltoimage --width 800 /root/#{file}.html /root/#{file}.png"])
    system("rm", ["#{file}.html"])
  end

  ECR.def_to_s "README.md.template"
end

File.write("README.md", Readme.new.to_s)
