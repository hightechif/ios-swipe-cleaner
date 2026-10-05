import Foundation

/// Composition root: builds repositories, use cases and view models once.
@MainActor
final class AppContainer {
    let persistence: PersistenceController
    let photoLibrary: PhotoLibraryRepository
    let authorizationService: PhotoAuthorizationService
    let keptPhotos: KeptPhotosRepository
    let trashedPhotos: TrashedPhotosRepository
    let imageLoader: ImageLoader

    let rootViewModel: RootViewModel
    let swipeViewModel: SwipeViewModel
    let trashViewModel: TrashViewModel
    let keptViewModel: KeptPhotosViewModel
    private let librarySync: LibrarySyncCoordinator

    init() {
        persistence = PersistenceController()
        photoLibrary = PhotoLibraryRepository()
        authorizationService = PhotoAuthorizationService()
        keptPhotos = KeptPhotosRepository(persistence: persistence)
        trashedPhotos = TrashedPhotosRepository(persistence: persistence)
        imageLoader = ImageLoader()

        rootViewModel = RootViewModel(authorizationService: authorizationService)

        let getKeptPhotos = GetKeptPhotosUseCase(keptPhotos: keptPhotos)
        let getTrashedPhotos = GetTrashedPhotosUseCase(trashedPhotos: trashedPhotos)
        let getAllMediaImages = GetAllMediaImagesUseCase(photoLibrary: photoLibrary)

        swipeViewModel = SwipeViewModel(
            getShuffledPhotoPool: GetShuffledPhotoPoolUseCase(
                photoLibrary: photoLibrary, keptPhotos: keptPhotos, trashedPhotos: trashedPhotos),
            markImageKept: MarkImageKeptUseCase(keptPhotos: keptPhotos),
            addToTrash: AddToTrashUseCase(trashedPhotos: trashedPhotos),
            getAllMediaImages: getAllMediaImages,
            findExistingPhotoIds: FindExistingPhotoIdsUseCase(photoLibrary: photoLibrary),
            getFilteredAlbums: GetFilteredAlbumsUseCase(),
            getKeptPhotos: getKeptPhotos,
            getTrashedPhotos: getTrashedPhotos
        )
        trashViewModel = TrashViewModel(
            getTrashedPhotos: getTrashedPhotos,
            deleteTrashedPhotos: DeleteTrashedPhotosUseCase(photoLibrary: photoLibrary, trashedPhotos: trashedPhotos),
            removeTrashedPhotos: RemoveTrashedPhotosUseCase(trashedPhotos: trashedPhotos),
            restoreFromTrash: RestoreFromTrashUseCase(trashedPhotos: trashedPhotos)
        )
        keptViewModel = KeptPhotosViewModel(
            getKeptPhotos: getKeptPhotos,
            resetKeptPhotos: ResetKeptPhotosUseCase(keptPhotos: keptPhotos),
            getAllMediaImages: getAllMediaImages,
            restoreFromKept: RestoreFromKeptUseCase(keptPhotos: keptPhotos)
        )

        librarySync = LibrarySyncCoordinator(
            libraryChanges: photoLibrary.changes,
            authorizationChanges: authorizationService.statusChanges,
            currentAuthorization: { [authorizationService] in authorizationService.status },
            pruneStaleDecisions: PruneStaleDecisionsUseCase(
                photoLibrary: photoLibrary, keptPhotos: keptPhotos, trashedPhotos: trashedPhotos),
            onLibraryChanged: { [swipeViewModel] in await swipeViewModel.refreshAfterLibraryChange() }
        )
    }
}
