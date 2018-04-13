config = Tendrl.load_config(ENV['RACK_ENV']).symbolize_keys
etcd_config = { host: config[:host], port: config[:port] }

if [config[:ca_cert_file], config[:client_cert_file], config[:client_key_file]]
  .all?{|c| c.present? }
  etcd_config.merge!(Tendrl.load_cert_config(config))
end

Tendrl::ETCD_CACHE = {}

Tendrl.etcd = Etcd.client(etcd_config).tap do |etcd|
  def etcd.cache
    Tendrl::ETCD_CACHE
  end

  def etcd.cached_get(path, opts = {})
    if cache[path].present? && cache[path]['updated'] > 5.minutes.ago
      return cache[path]['data']
    end
    cache[path] = {
      'data' => get(path, opts),
      'updated' => Time.now
    }
    cache[path]['data']
  end

  def etcd.cached_delete(path, opts = {})
    cache.delete path
    delete path, opts
  end
end
