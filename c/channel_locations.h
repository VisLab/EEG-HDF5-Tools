#ifndef _CHANNEL_LOCATIONS_H
#define _CHANNEL_LOCATIONS_H

/* structure for the channel locations compound data type */
struct channel_locations {
    char  *labels;
    char  *type;
    double theta;
    double radius;
    double X;
    double Y;
    double Z;
    double sph_theta;
    double sph_phi;
    double sph_radius;
    double urchan;
    char  *ref;
};

#endif
