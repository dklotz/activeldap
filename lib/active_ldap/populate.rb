module ActiveLdap
  module Populate
    module_function
    def ensure_base(base_class=nil)
      base_class ||= Base
      return unless base_class.search(:scope => :base).empty?

      base_dn = DN.parse(base_class.base)
      suffixes = []

      base_dn.rdns.reverse_each do |rdn|
        name, value = rdn.to_a[0]
        prefix = suffixes.join(",")
        suffixes.unshift("#{name}=#{value}")
        next unless name == "dc"
        begin
          ensure_dc(value, prefix, base_class)
        rescue ActiveLdap::OperationNotPermitted
        end
      end
    end

    def ensure_ou(name, base_class=nil)
      base_class ||= Base
      name = name.gsub(/\Aou\s*=\s*/i, '')

      ou_class = Class.new(base_class)
      ou_class.ldap_mapping(:dn_attribute => "ou",
                            :prefix => "",
                            :classes => ["top", "organizationalUnit"])
      return if ou_class.exist?(name)
      ou_class.new(name).save!
    end

    def ensure_dc(name, prefix, base_class=nil)
      base_class ||= Base
      name = name.gsub(/\Adc\s*=\s*/i, '')

      dc_class = Class.new(base_class)
      dc_class.ldap_mapping(:dn_attribute => "dc",
                            :prefix => "",
                            :scope => :base,
                            :classes => ["top", "dcObject", "organization"])
      dc_class.base = prefix
      return if dc_class.exist?(name)
      dc = dc_class.new(name)
      dc.o = dc.dc
      dc.save!
    end
  end
end
