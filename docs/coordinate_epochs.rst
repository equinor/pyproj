.. _coordinate_epochs:

Coordinate Epochs for Dynamic CRS
=================================

.. versionadded:: 3.8.0

Dynamic reference frames change over time due to tectonic plate motion and crustal
deformation. Examples include ITRF2014, ITRF2020, NAD83(CSRS), and GDA2020. To transform
coordinates between different epochs within the same dynamic CRS, use the ``source_epoch``
and ``target_epoch`` parameters in :meth:`pyproj.transformer.Transformer.from_crs`.

This provides equivalent functionality to the ``cs2cs`` command line options
``--s_epoch`` and ``--t_epoch``.


Dynamic vs Static CRS
---------------------

**Static CRS** (e.g., WGS 84 ensemble, NAD27):
    Coordinates do not change over time. The reference frame is considered fixed.

**Dynamic CRS** (e.g., ITRF2014, ITRF2020, NAD83(CSRS)v7):
    Coordinates change over time due to plate motion. Positions are associated with
    a specific epoch (point in time). In WKT2, these CRS have ``DYNAMIC[FRAMEEPOCH[...]]``
    or ``ANCHOREPOCH[...]`` elements.


Use Cases
---------

- **Survey adjustments**: Propagating survey coordinates to a common epoch
- **GNSS processing**: Converting coordinates between observation and reference epochs
- **Deformation monitoring**: Tracking land motion, subsidence, or uplift
- **Coordinate comparison**: Comparing datasets collected at different times
- **National reference frames**: Converting between epochs of national realizations


Basic Usage
-----------

Transform coordinates from epoch 2010 to epoch 2020 within NAD83(CSRS)v7:

.. code-block:: python

    from pyproj import Transformer

    transformer = Transformer.from_crs(
        "EPSG:8254",  # NAD83(CSRS)v7
        "EPSG:8254",  # Same CRS, different epoch
        source_epoch=2010.0,
        target_epoch=2020.0,
    )

    # Ottawa coordinates at epoch 2010
    lat_2010, lon_2010, h_2010 = 45.4215, -75.6972, 100.0

    # Transform to epoch 2020
    lat_2020, lon_2020, h_2020 = transformer.transform(lat_2010, lon_2010, h_2010)

    print(f"Height change: {h_2020 - h_2010:.4f} m")
    # Output: Height change: 0.0209 m (~21 mm in 10 years)

This matches the ``cs2cs`` command:

.. code-block:: bash

    echo "45.4215 -75.6972 100" | cs2cs EPSG:8254 EPSG:8254 --s_epoch 2010 --t_epoch 2020


Epoch vs Time Coordinate (tt)
-----------------------------

It's important to understand the difference between **CRS epochs** and
**time coordinates**:

**CRS Epochs** (``source_epoch``/``target_epoch``):
    The reference epoch for the entire coordinate system. This determines which
    velocity model parameters are used. All input coordinates are assumed to be
    at the source epoch, and all output coordinates are at the target epoch.

**Time Coordinate (``tt`` in transform)**:
    The observation time of individual points. Used in 4D transformations where
    each coordinate has its own associated timestamp. This is useful when you have
    a set of observations taken at different times.

Example:

.. code-block:: python

    # CRS epoch approach: All points from epoch 2010 to epoch 2020
    transformer = Transformer.from_crs(
        "EPSG:8254", "EPSG:8254",
        source_epoch=2010.0,
        target_epoch=2020.0,
    )
    result = transformer.transform(lat, lon, height)

    # Time coordinate approach: Different time for each point
    # (requires a different transformation setup)


Required Grids
--------------

Epoch transformations require velocity or deformation grids. These must be downloaded
separately. For NAD83(CSRS)v7, you need:

- ``ca_nrc_NAD83v70VG.tif`` - Canadian velocity grid

Download grids using:

.. code-block:: bash

    # Using pyproj sync
    pyproj sync --file ca_nrc_NAD83v70VG.tif

    # Or download all available grids
    pyproj sync --all

See :ref:`transformation_grids` for more information on obtaining grids.


Common Dynamic CRS
------------------

Here are some commonly used dynamic reference frames:

.. list-table::
   :header-rows: 1
   :widths: 20 30 20 30

   * - CRS
     - Name
     - Frame Epoch
     - Velocity Grid
   * - EPSG:8254
     - NAD83(CSRS)v7
     - 2010.0
     - ca_nrc_NAD83v70VG.tif
   * - EPSG:9988
     - ITRF2020 (geographic)
     - 2015.0
     - (built-in plate model)
   * - EPSG:9000
     - ITRF2014 (geographic)
     - 2010.0
     - (built-in plate model)
   * - EPSG:7912
     - ITRF2014 (geocentric)
     - 2010.0
     - (built-in plate model)


Error Handling
--------------

**Static CRS with epochs**:
    When you specify epochs for a static CRS, PROJ will not raise an error but will
    return unchanged coordinates (no-op transformation). This is because static CRS
    have no time-dependent component.

**Missing velocity grids**:
    If the required velocity grid is not available, PROJ may fall back to a less
    accurate transformation or raise an error. Use ``only_best=True`` to ensure
    you get an error rather than a fallback:

    .. code-block:: python

        transformer = Transformer.from_crs(
            "EPSG:8254", "EPSG:8254",
            source_epoch=2010.0,
            target_epoch=2020.0,
            only_best=True,  # Error if best transformation unavailable
        )


Complete Example
----------------

A complete example showing epoch transformation with error handling:

.. code-block:: python

    from pyproj import Transformer
    from pyproj.exceptions import ProjError

    def transform_to_epoch(
        coords: tuple[float, float, float],
        source_epoch: float,
        target_epoch: float,
        crs: str = "EPSG:8254",
    ) -> tuple[float, float, float]:
        """
        Transform coordinates from one epoch to another within a dynamic CRS.

        Parameters
        ----------
        coords : tuple
            (latitude, longitude, height) in degrees and meters
        source_epoch : float
            Source epoch as decimal year (e.g., 2010.0)
        target_epoch : float
            Target epoch as decimal year (e.g., 2020.0)
        crs : str
            CRS identifier (must be a dynamic CRS)

        Returns
        -------
        tuple
            (latitude, longitude, height) at target epoch
        """
        transformer = Transformer.from_crs(
            crs, crs,
            source_epoch=source_epoch,
            target_epoch=target_epoch,
        )
        return transformer.transform(*coords)

    # Example usage
    original = (45.4215, -75.6972, 100.0)
    result = transform_to_epoch(original, 2010.0, 2020.0)

    print(f"Original (2010): {original}")
    print(f"Result (2020):   {result}")
    print(f"Height change:   {result[2] - original[2]:.4f} m")


See Also
--------

- :ref:`transformation_grids` - How to download and manage transformation grids
- :ref:`network` - Network access for remote grids
- :meth:`pyproj.transformer.Transformer.from_crs` - API reference
- `PROJ CoordinateMetadata <https://proj.org/development/reference/cpp/metadata.html>`_ - PROJ C++ API
