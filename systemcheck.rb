class SystemCheck

  def ping_check_local()
    local_ping = `ping -c 2 192.168.11.1`.split(/\n/).reverse.take(2).reverse
  end

  def ping_check_server()
    serve_ping = `ping -c 2 google.com`.split(/\n/).reverse.take(2).reverse
  end

  def load_avelage()
    load_avelage = `w`.split(/\n/).take(1)
  end

end
