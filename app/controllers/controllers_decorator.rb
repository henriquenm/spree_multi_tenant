
class Spree::Preferences::StoreInstance
  # Initialize the preference without writing to the database
  def set_without_persist(key, value)
    @cache.write(key, value)
  end
end

module SpreeMultiTenant
  def self.init_preferences
    Spree::Preference.all.each do |preference|
      Spree::Preferences::Store.instance.set_without_persist(preference.key, preference.value)
    end
  end
end


SpreeMultiTenant.tenanted_controllers.each do |controller|
  controller.class_eval do

    set_current_tenant_through_filter
    before_filter :tenant_scope

    private
      
      def tenant_scope
        tenant = Spree::Tenant.find_by_domain(request.host)
        raise 'DomainUnknown' unless tenant

        set_current_tenant(tenant)

        # Add tenant views path
        path = "app/tenants/#{tenant.code}/views"
        prepend_view_path(path)

        # Execute ActiveRecord queries within the scope of the tenant
        SpreeMultiTenant.with_tenant tenant do
          yield
        end
      end

  end
end
