
SET(LOCAL_FILES
    crossing_edges.png
    touching_edges.png
    Dijkstra_Animation.gif
    )

foreach (f ${LOCAL_FILES})
    configure_file(${f} "${PGR_DOCUMENTATION_SOURCE_DIR}/images/${f}" COPYONLY)
    list(APPEND LOCAL_IMG_FILES  "${PGR_DOCUMENTATION_SOURCE_DIR}/images/${f}")
endforeach()

set(PROJECT_IMG_FILES ${PROJECT_IMG_FILES} ${LOCAL_IMG_FILES} PARENT_SCOPE)

