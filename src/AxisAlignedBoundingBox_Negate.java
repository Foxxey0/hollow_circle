// the point of this type of AABB is to act as an AABB that represents the INSIDE of something that should be EMPTY, which is why we calculate the min and max values differently to truncate the correct way.
public class AxisAlignedBoundingBox_Negate extends AxisAlignedBoundingBox {

    public AxisAlignedBoundingBox_Negate() {
        super();
    }

    public AxisAlignedBoundingBox_Negate(float xMin, float xMax, float yMin, float yMax, int parentWidth, int parentHeight) {
        super(xMin, xMax, yMin, yMax, parentWidth, parentHeight);
    }

    @Override
    protected void convertToInts() {
        xMin_INT = (int) xMin;
        xMax_INT = (int) xMax +1;
        yMin_INT = (int) yMin;
        yMax_INT = (int) yMax +1;
    }

    @Override
    public void setxMin(float xMin) {
        this.xMin = xMin;
        xMin_INT = (int) xMin; // set the INT version
        xMin_INT_clamped = Math.min(Math.max(xMin_INT, 0), parentWidth -1); // set the clamped INT version
    }

    @Override
    public void setxMax(float xMax) {
        this.xMax = xMax;
        xMax_INT = (int) xMax +1; // set the INT version
        xMax_INT_clamped = Math.min(Math.max(xMax_INT, 0), parentWidth -1); // set the clamped INT version
    }

    @Override
    public void setyMin(float yMin) {
        this.yMin = yMin;
        yMin_INT = (int) yMin; // set the INT version
        yMin_INT_clamped = Math.min(Math.max(yMin_INT, 0), parentHeight -1); // set the clamped INT version
    }

    @Override
    public void setyMax(float yMax) {
        this.yMax = yMax;
        yMax_INT = (int) yMax +1; // set the INT version
        yMax_INT_clamped = Math.min(Math.max(yMax_INT, 0), parentHeight -1); // set the clamped INT version
    }

}
