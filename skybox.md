## Goal
Mapping a given 2D screenspace coordinate (point in camera) to one or more stars visible at that point (lat- and longitude), their distances and their radii.

Given:
- A 2D screenspace coordinate, or point in the camera;
- The translation and rotation of the camera, relative to Sol;
- The celestial coordinates, distances and radii of all stars, relative to Sol

Goal:
- A mapping from a given 2D screenspace coordinate to a list of stars visible at that point, and to their distances from the camera and their (angular) radii.

Approach:
1. Map the 2D screenspace coordinate to a lat- and longitude

Possible solutions:
- Instead of rendering directly to the camera, the stars can be rendered to a sphere with inverse faces and its origin at the camera. This way, calculating the absolute lat- and longitude of a pixel from a 2D screenspace coordinate is not necessary.
  
  A downside to this is that it might require rendering the entirety of the sphere's surface, including the area invisible to the camera.

## Mathematical tools
Conversion of right ascension $RA$ and declination $dec$ to angles $\alpha$ and $\delta$ in degrees:
$$
\begin{align}
	\alpha &= 15 * RA \\
	&= 15 * \left( RA_{hr} + \frac{RA_{min}}{60} + \frac{RA_{sec}}{3600} \right) \\
	&= 15 * RA_{hr} + \frac{RA_{min}}{4} + \frac{RA_{sec}}{240}
\end{align}
$$
$$
\delta = dec_{sign} * \left( |dec_{deg}| + \frac{dec_{min}}{60} + \frac{dec_{sec}}{3600} \right)
$$
Constraints/bounds of right ascension $RA$ in seconds, angle $\alpha$ in degrees, declination $dec$ in arcseconds and angle $\delta$ in degrees:
$$0 * 3600 = 0 \leq RA < 24 * 3600 = 86400$$
$$0 \leq \alpha < 360$$
$$-90 * 3600 = -324000 < dec < 90 * 3600 = 324000$$
$$0 \leq \delta < 360$$
Conversion of angles $\alpha$ and $\delta$ and distance $r$ to cartesian coordinate $P$:
$$
\begin{align}
	P = 
	\begin{bmatrix}
		x \\
		y \\
		z
	\end{bmatrix}
	=
	\begin{bmatrix}
		r * \cos\delta * \cos\alpha \\
		r * \cos\delta * \sin\alpha \\
		r * \sin\delta
	\end{bmatrix}
\end{align}
$$
Conversion from 2D coordinate $P$ in a rectangle with size $S$ to latitude $\phi$ and longitude $\lambda$ in degrees (spherical coordinates):
$$
\phi = 360\degree * \left( \frac{2 * P_x}{S_x} - 1 \right) 
$$
$$
\lambda = 180\degree * \left( \frac{2 * P_y}{S_y} - 1 \right)
$$
## Data structure
The data will be accessible to the shader in the form of a texture.

Wether this texture is 2D or 3D, the $x$- and $y$ axes of the texture will represent celestial coordinates relative to Sol.

Since multiple stars at multiple distances may be along roughly the same right ascension and declination a choice must be made: Either only one star can be mapped to a precise celestial coordinate, or a 3D texture is needed. The first option might cost the loss of a tiny amount of data, causing a few stars to not be visible. The second option would cost a lot more effort, if it is even possible due to technical restrictions.

Because both the distance and the radius of each star are required information, and each value would take exactly the 4 bytes of an RGBA pixel, either the width or the height of the texture has to be doubled. The distance and radius can then be stored in adjacency. The data of a star can thus be found at $(2 * RA\ ,\ dec)$ or $(RA\ ,\ 2 * dec)$, depending on the axis. 
