root = File.expand_path('../..', __FILE__)

def run cmd
  fork { exec cmd }
end

pids = []

pids << run("jekyll build #{root} #{root}/_site --watch")
pids << run("compass watch #{root} -c #{root}/_config/compass.rb")

system "open #{root}/_site/index.html"

Process.waitpid pids[0]
Process.waitpid pids[1]
