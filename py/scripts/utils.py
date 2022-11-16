import numpy as np
import SimpleITK as sitk


def resize(img, new_size, interpolator):
    # img = sitk.ReadImage(img)
    dimension = img.GetDimension()

    # Physical image size corresponds to the largest physical size in the training set, or any other arbitrary size.
    reference_physical_size = np.zeros(dimension)

    reference_physical_size[:] = [(sz - 1) * spc if sz * spc > mx else mx for sz, spc, mx in
                                  zip(img.GetSize(), img.GetSpacing(), reference_physical_size)]

    # Create the reference image with a zero origin, identity direction cosine matrix and dimension
    reference_origin = np.zeros(dimension)
    reference_direction = np.identity(dimension).flatten()
    reference_size = new_size
    reference_spacing = [
        phys_sz / (sz - 1) for sz, phys_sz in zip(reference_size, reference_physical_size)]

    reference_image = sitk.Image(reference_size, img.GetPixelIDValue())
    reference_image.SetOrigin(reference_origin)
    reference_image.SetSpacing(reference_spacing)
    reference_image.SetDirection(reference_direction)

    # Always use the TransformContinuousIndexToPhysicalPoint to compute an indexed point's physical coordinates as
    # this takes into account size, spacing and direction cosines. For the vast majority of images the direction
    # cosines are the identity matrix, but when this isn't the case simply multiplying the central index by the
    # spacing will not yield the correct coordinates resulting in a long debugging session.
    reference_center = np.array(
        reference_image.TransformContinuousIndexToPhysicalPoint(np.array(reference_image.GetSize()) / 2.0))

    # Transform which maps from the reference_image to the current img with the translation mapping the image
    # origins to each other.
    transform = sitk.AffineTransform(dimension)
    transform.SetMatrix(img.GetDirection())
    transform.SetTranslation(np.array(img.GetOrigin()) - reference_origin)
    # Modify the transformation to align the centers of the original and reference image instead of their origins.
    centering_transform = sitk.TranslationTransform(dimension)
    img_center = np.array(img.TransformContinuousIndexToPhysicalPoint(
        np.array(img.GetSize()) / 2.0))
    centering_transform.SetOffset(
        np.array(transform.GetInverse().TransformPoint(img_center) - reference_center))

    # centered_transform = sitk.Transform(transform)
    # centered_transform.AddTransform(centering_transform)

    centered_transform = sitk.CompositeTransform(
        [transform, centering_transform])

    # Using the linear interpolator as these are intensity images, if there is a need to resample a ground truth
    # segmentation then the segmentation image should be resampled using the NearestNeighbor interpolator so that
    # no new labels are introduced.

    return sitk.Resample(img, reference_image, centered_transform, interpolator, 0.0)


def resample_sitk_image(sitk_image, spacing=None, interpolator=None, fill_value=0):
    # https://github.com/SimpleITK/SlicerSimpleFilters/blob/master/SimpleFilters/SimpleFilters.py
    _SITK_INTERPOLATOR_DICT = {
        'nearest': sitk.sitkNearestNeighbor,
        'linear': sitk.sitkLinear,
        'gaussian': sitk.sitkGaussian,
        'label_gaussian': sitk.sitkLabelGaussian,
        'bspline': sitk.sitkBSpline,
        'hamming_sinc': sitk.sitkHammingWindowedSinc,
        'cosine_windowed_sinc': sitk.sitkCosineWindowedSinc,
        'welch_windowed_sinc': sitk.sitkWelchWindowedSinc,
        'lanczos_windowed_sinc': sitk.sitkLanczosWindowedSinc
    }

    if isinstance(sitk_image, str):
        sitk_image = sitk.ReadImage(sitk_image)
    num_dim = sitk_image.GetDimension()

    if not interpolator:
        interpolator = 'linear'
        pixelid = sitk_image.GetPixelIDValue()

        if pixelid not in [1, 2, 4]:
            raise NotImplementedError(
                'Set `interpolator` manually, '
                'can only infer for 8-bit unsigned or 16, 32-bit signed integers')
        if pixelid == 1:  # 8-bit unsigned int
            interpolator = 'nearest'

    orig_pixelid = sitk_image.GetPixelIDValue()
    orig_origin = sitk_image.GetOrigin()
    orig_direction = sitk_image.GetDirection()
    orig_spacing = np.array(sitk_image.GetSpacing())
    orig_size = np.array(sitk_image.GetSize(), dtype=np.int)

    if not spacing:
        min_spacing = orig_spacing.min()
        new_spacing = [min_spacing] * num_dim
    else:
        new_spacing = [float(s) for s in spacing]

    assert interpolator in _SITK_INTERPOLATOR_DICT.keys(), \
        '`interpolator` should be one of {}'.format(
            _SITK_INTERPOLATOR_DICT.keys())

    sitk_interpolator = _SITK_INTERPOLATOR_DICT[interpolator]

    new_size = orig_size * (orig_spacing / new_spacing)
    # Image dimensions are in integers
    new_size = np.ceil(new_size).astype(np.int)
    # SimpleITK expects lists, not ndarrays
    new_size = [int(s) for s in new_size]

    resample_filter = sitk.ResampleImageFilter()

    resample_filter.SetOutputSpacing(new_spacing)
    resample_filter.SetSize(new_size)
    resample_filter.SetOutputDirection(orig_direction)
    resample_filter.SetOutputOrigin(orig_origin)
    resample_filter.SetTransform(sitk.Transform())
    resample_filter.SetDefaultPixelValue(orig_pixelid)
    resample_filter.SetInterpolator(sitk_interpolator)
    resample_filter.SetDefaultPixelValue(fill_value)

    resampled_sitk_image = resample_filter.Execute(sitk_image)

    return resampled_sitk_image


def equalization(image, label=None):
    image_array = sitk.GetArrayFromImage(image)
    img1 = np.zeros((image_array.shape[0], image_array.shape[1], 85))
    img1 = image_array[:, :, int(
        image_array.shape[2]/2-85/2):int(image_array.shape[2]/2+85/2)]
    img1 = (img1 - img1.min()) / (img1.max() - img1.min())
    img1 = img1*255
    hist1, bins1 = np.histogram(img1.flatten(), 256, [0, 256])
    cdf1 = hist1.cumsum()
    cdf_m = np.ma.masked_equal(cdf1, 0)
    cdf_m = (cdf_m - cdf_m.min())*255/(cdf_m.max()-cdf_m.min())
    cdf = np.ma.filled(cdf_m, 0).astype('uint8')
    img2 = cdf[img1.astype(np.uint8)]
    if label:
        label_array = sitk.GetArrayFromImage(label)
        label1 = np.zeros((image_array.shape[0], image_array.shape[1], 85))
        label1 = label_array[:, :, int(
            image_array.shape[2]/2-85/2):int(image_array.shape[2]/2+85/2)]
        label = sitk.GetImageFromArray(label1)
    return sitk.GetImageFromArray(img2), label


def copyInformation(sourceImage, newImage):
    # copy the direction
    newImage.SetDirection(sourceImage.GetDirection())
    # copy the spacing
    newImage.SetSpacing(sourceImage.GetSpacing())

    newImage.SetOrigin(sourceImage.GetOrigin())
    # return newImage


def uniform_img_dimensions(image, label, nearest):
    image_array = sitk.GetArrayFromImage(image)
    # reshape array from itk z,y,x  to  x,y,z
    image_array = np.transpose(image_array, axes=(2, 1, 0))
    image_shape = image_array.shape

    if nearest is True:
        label = resample_sitk_image(
            label, spacing=image.GetSpacing(), interpolator='nearest')
        res = resize(label, image_shape, sitk.sitkNearestNeighbor)
        res = (np.rint(sitk.GetArrayFromImage(res)))
        res = sitk.GetImageFromArray(res.astype('uint8'))
        # print(res.GetSize())

    else:
        label = resample_sitk_image(
            label, spacing=image.GetSpacing(), interpolator='linear')
        res = resize(label, image_shape, sitk.sitkLinear)
        res = (np.rint(sitk.GetArrayFromImage(res)))
        res = sitk.GetImageFromArray(res.astype('float'))

    res.SetDirection(image.GetDirection())
    res.SetOrigin(image.GetOrigin())
    res.SetSpacing(image.GetSpacing())

    return image, res


def applyMask(image, mask):
    image_array = sitk.GetArrayFromImage(image)
    mask_array = sitk.GetArrayFromImage(mask)

    masked_image_array = image_array * mask_array
    masked_image = sitk.GetImageFromArray(masked_image_array)

    return masked_image


def setProperty(img, spacing, direction):
    img.SetDirection(direction)
    img.SetSpacing(spacing)
    return img
