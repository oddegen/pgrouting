..
   ****************************************************************************
    pgRouting Manual
    Copyright(c) pgRouting Contributors

    This documentation is licensed under a Creative Commons Attribution-Share
    Alike 3.0 License: https://creativecommons.org/licenses/by-sa/3.0/
   ****************************************************************************

.. index::
   single: Utilities ; pgr_extractVertices
   single: extractVertices

|

``pgr_extractVertices``
===============================================================================

``pgr_extractVertices`` — Extracts the vertices information

.. rubric:: Availability

.. rubric:: Version 3.8.0

* Error messages adjustment.
* Function promoted to official.

.. rubric:: Version 3.3.0

* Function promoted to proposed.

.. rubric:: Version 3.0.0

* New experimental function.


Description
-------------------------------------------------------------------------------

This is an auxiliary function for extracting the vertex information of the set
of edges of a graph.

* When the edge identifier is given, then it will also calculate the in and out
  edges


|Boost| Boost Graph Inside

Signatures
-------------------------------------------------------------------------------

.. admonition:: \ \
   :class: signatures

   | pgr_extractVertices(`Edges SQL`_, [``dryrun``])

   | RETURNS SETOF |result-extract|
   | OR EMPTY SET

:Example: Extracting the vertex information

.. literalinclude:: extractVertices.queries
   :start-after: --q1
   :end-before: --q1.1


Parameters
-------------------------------------------------------------------------------

============== ========  ================================
Parameter      Type      Description
============== ========  ================================
`Edges SQL`_   ``TEXT``  `Edges SQL`_ as described below
============== ========  ================================

Optional parameters
-------------------------------------------------------------------------------

=========== =============  ========== =======================================
Parameter    Type          Default    Description
=========== =============  ========== =======================================
``dryrun``  ``BOOLEAN``    ``false``  * When true do not process and get in a
                                        NOTICE the resulting query.
=========== =============  ========== =======================================

Inner Queries
-------------------------------------------------------------------------------

.. contents::
   :local:

Edges SQL
...............................................................................

When line geometry is known
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

================= =================== ===================================
Column            Type                Description
================= =================== ===================================
``id``            ``BIGINT``          (Optional) identifier of the edge.
``geom``          ``LINESTRING``      Geometry of the edge.
================= =================== ===================================

This inner query takes precedence over the next two inner query, therefore other
columns are ignored when ``geom`` column appears.

* Ignored columns:

  * ``startpoint``
  * ``endpoint``
  * ``source``
  * ``target``

When vertex geometry is known
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

To use this inner query the column ``geom`` should not be part of the set of
columns.

================= =================== =======================================
Column            Type                Description
================= =================== =======================================
``id``            ``BIGINT``          (Optional) identifier of the edge.
``startpoint``    ``POINT``           POINT geometry of the starting vertex.
``endpoint``      ``POINT``           POINT geometry of the ending vertex.
================= =================== =======================================

This inner query takes precedence over the next inner query, therefore other
columns are ignored when ``startpoint`` and ``endpoint`` columns appears.

* Ignored columns:

  * ``source``
  * ``target``

When identifiers of vertices are known
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

To use this inner query the columns ``geom``, ``startpoint`` and ``endpoint``
should not be part of the set of columns.

============= =============== ==========================================
Column        Type            Description
============= =============== ==========================================
``id``        ``BIGINT``      (Optional) identifier of the edge.
``source``    ``ANY-INTEGER`` Identifier of the first end point vertex
                              of the edge.
``target``    ``ANY-INTEGER`` Identifier of the second end point vertex
                              of the edge.
============= =============== ==========================================


Result columns
-------------------------------------------------------------------------------

.. list-table::
   :width: 81
   :widths: auto
   :header-rows: 1

   * - Column
     - Type
     - Description
   * - ``id``
     - ``BIGINT``
     - Vertex identifier
   * - ``in_edges``
     - ``BIGINT[]``
     - Array of identifiers of the edges that have the vertex ``id`` as *first
       end point*.

       * ``NULL`` When the ``id`` is not part of the inner query
   * - ``out_edges``
     - ``BIGINT[]``
     - Array of identifiers of the edges that have the vertex ``id`` as *second
       end point*.

       * ``NULL`` When the ``id`` is not part of the inner query
   * - ``x``
     - ``FLOAT``
     - X value of the point geometry

       * ``NULL`` When no geometry is provided
   * - ``y``
     - ``FLOAT``
     - X value of the point geometry

       * ``NULL`` When no geometry is provided
   * - ``geom``
     - ``POINT``
     - Geometry of the point

       * ``NULL`` When no geometry is provided

Additional Examples
-------------------------------------------------------------------------------

.. contents::
   :local:

Dry run execution
...............................................................................

To get the query generated used to get the vertex information, use ``dryrun :=
true``.

The results can be used as base code to make a refinement based on the backend
development needs.

.. literalinclude:: extractVertices.queries
   :start-after: --q2
   :end-before: --q2.1


Create a routing topology
...............................................................................

.. create_routing_topology_start

Make sure the database does not have the ``vertices_table``
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. literalinclude:: extractVertices.queries
   :start-after: --q3
   :end-before: --q3.1

Clean up the columns of the routing topology to be created
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. literalinclude:: extractVertices.queries
   :start-after: --q3.1
   :end-before: --q3.2

Create the vertices table
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

* When the ``LINESTRING`` has a SRID then use ``geom::geometry(POINT, <SRID>)``
* For big edge tables that are been prepared,

  * Create it as ``UNLOGGED`` and
  * After the table is created ``ALTER TABLE .. SET LOGGED``

.. literalinclude:: extractVertices.queries
   :start-after: --q3.2
   :end-before: --q3.3

Inspect the vertices table
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. literalinclude:: extractVertices.queries
   :start-after: --q3.3
   :end-before: --q3.4

Create the routing topology on the edge table
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Updating the ``source`` information

.. literalinclude:: extractVertices.queries
   :start-after: --q3.4
   :end-before: --q3.5

Updating the ``target`` information

.. literalinclude:: extractVertices.queries
   :start-after: --q3.5
   :end-before: --q3.6

Inspect the routing topology
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. literalinclude:: extractVertices.queries
   :start-after: --q3.6
   :end-before: --q3.7

.. figure:: /images/Fig1-originalData.png
   :scale: 50%

   **Generated topology**

.. create_routing_topology_end

See Also
-------------------------------------------------------------------------------

* :doc:`topology-functions`

.. rubric:: Indices and tables

* :ref:`genindex`
* :ref:`search`
