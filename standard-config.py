from Products.ExternalMethod.ExternalMethod import manage_addExternalMethod
# we add the external method cputils_install
if not hasattr(app, 'cputils_install'):
    manage_addExternalMethod(app, 'cputils_install', '', 'CPUtils.utils', 'install')
# we run this method
app.cputils_install(app)
# we add the properties hiddenProducts, shownProducts
#from Products.CPUtils.hiddenProductsList import dic_hpList
# to be continued