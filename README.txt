This buildout relates the configuration of the application zope instance of the CommunesPlone central server.

The main config file is buildout.cfg.
Is is empty by default.
It's necessary to call in it a subconfig file name: dev.cfg, prod.cfg, ...

The included external products are listed in cfg file:
    - section [productdistros] (release form)
    - section [svnproducts] (svn form)
    - subsection eggs

The directory 'parts/omelette/Products' contains (as links) all the used products. 

Outside zeo mode (dev.cfg), a "zope_add.conf" extends the generated zope.conf to add mount_points definition. 
In zeo mode (prod.cfg), a "zope_add_zeo.conf" and "zeo_add.conf" extend the generated zope.conf and zeo.conf to add mount_points definition. 

The install process is described in the file : INSTALL.txt
