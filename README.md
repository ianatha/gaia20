# gaia20

A global government-data discovery API based on DNS

Imagine something like global yellow pages for government services across jursidctions, using a standardized format, on top of DNS.

A DNS-based directory for government services, aspiring to span the entire world.

The idea is that you should be able to go to 

                   _web.covid19.PUBHEALTH.svc.USA.govt.v0.gaia20.com -- REDIRECT to CDC's COVID19 page
                           _web.PUBHEALTH.svc.USA.govt.v0.gaia20.com -- CNAME to www.cdc.gov
          _web.covid19.PUBHEALTH.svc.IOWA.jrs.USA.govt.v0.gaia20.com -- REDIRECT Iowa Department of Public Health's COVID19 page
    _web.covid19.PUBHEALTH.svc.CALIFORNIA.jrs.USA.govt.v0.gaia20.com -- REDIRECT California's Department of Public Health's COVID19 page
                   _web.covid19.PUBHEALTH.svc.GRC.govt.v0.gaia20.com -- REDIRECT Greece's Department of Public Health COVID19 page


The API defined in this repository is the format of the DNS name requested, and the expected output...

We're currently working on the 'govt.v0' subdomain.

Under the 'govt.v0', you will find subzones for each UN-recognized country. Such countries are referenced by their 3-letter ISO code.

We're currently working on coverage for USA, GRC, and ITA.

Under each country zone in the `govt.v0` scheme, you can expect to find two subzeones:
* the `svc` subzone, for Governmental services provided for the entirety of the jurisdiction -- see the `svc` subzone definition
* the `jrs` subzone, for administative subdivisions of the country, for example States, for the United States

We use internationalized names to refer to the authority in each country.

For example, "PUBHEALTH" maps to the CDC (Center for Disease Control) at the USA level, and to the "National Public Health Organization" for Greece (and not the Ministry of Health).

## Subzone Delegation

We're happy to delegate parts of the DNS zone collaborators who agree to keep up with our API definitions.

For example, GRC.govt.v0.gaia20.com and ITA.govt.v0.gaia20.com have been delegated to groups ran by volunteers in Greece and Italy.
